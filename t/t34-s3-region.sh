#! /usr/bin/env bash

# BM_UPLOAD_S3_REGION / --s3-region must reach Net::Amazon::S3, and leave the
# calls unchanged when unset (backward compatibility).

set -e

source testlib.sh

workdir=$(mktemp -d "${TMPDIR:-/tmp}/bm-t34-XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# A fake Net::Amazon::S3 that logs how it is called into FAKE_S3_LOG.
mkdir -p "$workdir/lib/Net/Amazon"
cat > "$workdir/lib/Net/Amazon/S3.pm" <<'EOF'
package Net::Amazon::S3;
our $VERSION = '0.99';
our %keys;
sub _log { open my $fh, '>>', $ENV{FAKE_S3_LOG} or die; print $fh "@_\n"; close $fh }
sub new {
    my ($class, $args) = @_;
    _log("new auth=" . ($args->{authorization_method} // 'none'));
    return bless {}, $class;
}
sub err    { return undef }
sub errstr { return undef }
sub bucket {
    my ($s3, $arg) = @_;
    if (ref $arg) { _log("bucket name=$arg->{bucket} region=$arg->{region}") }
    else          { _log("bucket plain=$arg") }
    return bless {}, 'Net::Amazon::S3::FakeBucket';
}
package Net::Amazon::S3::FakeBucket;
sub list {
    return { bucket => 'test',
             keys => [ map { { key => $_, size => $Net::Amazon::S3::keys{$_} } }
                       keys %Net::Amazon::S3::keys ] };
}
sub add_key_filename {
    my ($self, $key, $file) = @_;
    $Net::Amazon::S3::keys{$key} = -s $file;
    return 1;
}
1;
EOF

repository="$workdir/repository"
mkdir -p "$repository"
head -c 100 /dev/zero > "$repository/host-test.$(date +%Y%m%d).tar"

function run_bmu()
{
    FAKE_S3_LOG="$workdir/log" PERL5LIB="$workdir/lib:..${PERL5LIB:+:$PERL5LIB}" \
        perl ../backup-manager-upload -m s3 -h s3.amazonaws.com -u key -p secret \
            -b test -r "$repository" "$@" today >/dev/null 2>&1
}

# 1. region given: SigV4 + region on the bucket
: > "$workdir/log"
run_bmu --s3-region eu-west-1 || exit 10
grep -qx "new auth=Net::Amazon::S3::Signature::V4" "$workdir/log" || exit 11
grep -qx "bucket name=test region=eu-west-1" "$workdir/log" || exit 12

# 2. no region: exactly the historical calls
: > "$workdir/log"
run_bmu || exit 20
grep -qx "new auth=none" "$workdir/log" || exit 21
grep -qx "bucket plain=test" "$workdir/log" || exit 22

# 3. shell wiring: the flag is only passed when the variable is set
source confs/base.conf
source $locallib/sanitize.sh
export BM_TEMP_DIR="$workdir"
cat > "$workdir/fake-bmu" <<EOF
#! /usr/bin/env bash
echo "\$@" > "$workdir/args"
EOF
chmod +x "$workdir/fake-bmu"
bmu="$workdir/fake-bmu"

BM_UPLOAD_S3_REGION="eu-west-1"
bm_upload_s3
grep -q -- "--s3-region=eu-west-1" "$workdir/args" || exit 30

BM_UPLOAD_S3_REGION=""
bm_upload_s3
grep -q -- "--s3-region" "$workdir/args" && exit 31

exit 0
