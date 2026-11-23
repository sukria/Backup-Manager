#! /usr/bin/env bash

# Issue #94: when the bucket cannot be read or created, backup-manager-upload
# must fail with E_S3_FAILED (22) and report the S3 error, instead of crashing
# on "Can't locate object method add_key_filename via package 0".

set -e

source testlib.sh

workdir=$(mktemp -d "${TMPDIR:-/tmp}/bm-t33-XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# A fake Net::Amazon::S3 whose bucket behaviour is driven by FAKE_S3_MODE.
mkdir -p "$workdir/lib/Net/Amazon"
cat > "$workdir/lib/Net/Amazon/S3.pm" <<'EOF'
package Net::Amazon::S3;
our $VERSION = '0.99';
our %keys;
our $created = 0;
sub new    { return bless {}, shift }
sub err    { return $_[0]{err} }
sub errstr { return $_[0]{errstr} }
sub bucket { my ($s3) = @_; return bless { s3 => $s3 }, 'Net::Amazon::S3::FakeBucket' }
sub add_bucket {
    my ($s3) = @_;
    if ($ENV{FAKE_S3_MODE} eq 'create_fails') {
        $s3->{err}    = 'BucketAlreadyExists';
        $s3->{errstr} = 'The requested bucket name is not available';
        return 0;
    }
    $created = 1;
    return bless { s3 => $s3 }, 'Net::Amazon::S3::FakeBucket';
}
package Net::Amazon::S3::FakeBucket;
sub list {
    my ($self) = @_;
    my $s3   = $self->{s3};
    my $mode = $ENV{FAKE_S3_MODE};
    if ($mode eq 'list_denied') {
        $s3->{err}    = 'PermanentRedirect';
        $s3->{errstr} = 'The bucket you are attempting to access must be addressed using the specified endpoint.';
        return undef;
    }
    if (not $Net::Amazon::S3::created) {
        if ($mode ne 'legacy') {
            $s3->{err}    = 'NoSuchBucket';
            $s3->{errstr} = 'The specified bucket does not exist';
        }
        return undef;
    }
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

# run_bmu MODE: runs the upload, leaves its output in $workdir/out.MODE,
# prints the exit code.
function run_bmu()
{
    local mode="$1" rc=0
    FAKE_S3_MODE="$mode" PERL5LIB="$workdir/lib:..${PERL5LIB:+:$PERL5LIB}" \
        perl ../backup-manager-upload -m s3 -h s3.amazonaws.com -u key -p secret \
            -b test -r "$repository" today >"$workdir/out.$mode" 2>&1 || rc=$?
    echo "$rc"
}

# 1. bucket exists but is unreadable (wrong region): fail, do not create
rc=$(run_bmu list_denied)
[[ "$rc" == "22" ]] || exit 10
grep -q "PermanentRedirect" "$workdir/out.list_denied" || exit 11
grep -q "does not exist" "$workdir/out.list_denied" && exit 12
grep -q "Can't locate object method" "$workdir/out.list_denied" && exit 13

# 2. bucket missing and creation refused: fail with the S3 reason
rc=$(run_bmu create_fails)
[[ "$rc" == "22" ]] || exit 20
grep -q "Could not create bucket test: The requested bucket name is not available" \
    "$workdir/out.create_fails" || exit 21
grep -q "Can't locate object method" "$workdir/out.create_fails" && exit 22

# 3. bucket missing, creation works: upload succeeds
rc=$(run_bmu create_ok)
[[ "$rc" == "0" ]] || exit 30

# 4. old Net::Amazon::S3 that sets no error on a missing bucket: still creates
rc=$(run_bmu legacy)
[[ "$rc" == "0" ]] || exit 40

exit 0
