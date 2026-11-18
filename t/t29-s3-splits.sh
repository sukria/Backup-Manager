#! /usr/bin/env bash

# Make sure the chunks created when splitting archives bigger than the S3
# max size are removed once uploaded, while the original archive is kept.

set -e

source testlib.sh

workdir=$(mktemp -d "${TMPDIR:-/tmp}/bm-t29-XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# A fake Net::Amazon::S3 that records uploads in memory.
mkdir -p "$workdir/lib/Net/Amazon"
cat > "$workdir/lib/Net/Amazon/S3.pm" <<'EOF'
package Net::Amazon::S3;
our $VERSION = '0.99';
my %keys;
sub new { return bless {}, shift }
sub bucket { return bless {}, 'Net::Amazon::S3::FakeBucket' }
package Net::Amazon::S3::FakeBucket;
sub list {
    return { bucket => 'test',
             keys => [ map { { key => $_, size => $keys{$_} } } keys %keys ] };
}
sub add_key_filename {
    my ($self, $key, $file) = @_;
    $keys{$key} = -s $file;
    return 1;
}
1;
EOF

repository="$workdir/repository"
mkdir -p "$repository"
date=$(date +%Y%m%d)
archive="$repository/host-test.$date.tar"
head -c 2500 /dev/zero > "$archive"

PERL5LIB="$workdir/lib:..${PERL5LIB:+:$PERL5LIB}" \
    perl ../backup-manager-upload -m s3 -h s3.amazonaws.com -u key -p secret \
        -b test -r "$repository" --s3-maxsize 1000 today >/dev/null 2>&1

# the original archive must be kept
[[ -f "$archive" ]]

# the chunks must be gone
if ls "$archive"-split-* >/dev/null 2>&1; then
    exit 1
fi

exit 0
