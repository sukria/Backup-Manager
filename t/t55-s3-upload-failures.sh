#! /usr/bin/env bash

# Make sure the S3 upload method only records archives that really reached
# the bucket: a failed or lost upload must be reported and retried by the
# next run, and buckets bigger than one listing page must be fully listed
# when confirming uploads and purging.

set -e

source testlib.sh

workdir=$(mktemp -d "${TMPDIR:-/tmp}/bm-t55-XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# A fake Net::Amazon::S3 keeping the bucket in memory.
#  FAKE_S3_MODE   fail: add_key_filename returns false and sets errstr
#                 die:  add_key_filename dies
#                 lose: add_key_filename returns true but stores nothing
#  FAKE_S3_MATCH  regexp of the keys FAKE_S3_MODE applies to
#  FAKE_S3_PREFILL space-separated keys already in the bucket
#  FAKE_S3_LOG    file receiving one "delete <key>" line per deleted key
#  FAKE_S3_NO_LIST_ALL  set to remove list_all(), like old releases
#  FAKE_S3_LIST_DIES    set to make listings die once the uploads started
# list() returns pages of at most 2 keys after the given marker;
# list_all() returns every key.
mkdir -p "$workdir/lib/Net/Amazon"
cat > "$workdir/lib/Net/Amazon/S3.pm" <<'EOF'
package Net::Amazon::S3;
our $VERSION = '0.99';
my %keys = map { $_ => 1 } split ' ', ($ENV{FAKE_S3_PREFILL} || '');
my ($err, $errstr);
my $uploads_started;
sub new { return bless {}, shift }
sub bucket { return bless {}, 'Net::Amazon::S3::FakeBucket' }
sub err { return $err }
sub errstr { return $errstr }
package Net::Amazon::S3::FakeBucket;
sub _keys { return [ map { { key => $_, size => $keys{$_} } } @_ ] }
sub _check { die "Service unavailable\n" if $uploads_started and $ENV{FAKE_S3_LIST_DIES} }
sub list {
    my ($self, $conf) = @_;
    _check();
    my $marker = $conf && $conf->{marker};
    my @all = grep { not defined $marker or $_ gt $marker } sort keys %keys;
    my $truncated = @all > 2 ? 1 : 0;
    splice @all, 2 if $truncated;
    return { bucket => 'test', is_truncated => $truncated, keys => _keys(@all) };
}
sub list_all {
    _check();
    return { bucket => 'test', keys => _keys(sort keys %keys) };
}
delete $Net::Amazon::S3::FakeBucket::{list_all} if $ENV{FAKE_S3_NO_LIST_ALL};
sub delete_key {
    my ($self, $key) = @_;
    delete $keys{$key};
    if (open my $fh, '>>', $ENV{FAKE_S3_LOG}) { print $fh "delete $key\n" }
    return 1;
}
sub add_key_filename {
    my ($self, $key, $file) = @_;
    $uploads_started = 1;
    my $mode = $ENV{FAKE_S3_MODE} || '';
    my $match = $ENV{FAKE_S3_MATCH};
    if (defined $match and $key =~ /$match/) {
        if ($mode eq 'fail') {
            ($err, $errstr) = ('AccessDenied', 'Access Denied');
            return 0;
        }
        die "Connection reset by peer\n" if $mode eq 'die';
        return 1 if $mode eq 'lose';
    }
    $keys{$key} = -s $file;
    return 1;
}
1;
EOF

date=$(date +%Y%m%d)

# Run one upload in a fresh repository holding a small archive and an
# archive split in three chunks. Sets $status to the exit code.
function run_upload()
{
    repository="$workdir/repository"
    rm -rf "$repository"
    mkdir -p "$repository"
    small="$repository/host-small.$date.tar"
    big="$repository/host-big.$date.tar"
    head -c 500 /dev/zero > "$small"
    head -c 2500 /dev/zero > "$big"
    database="$workdir/uploaded"
    : > "$database"
    : > "$workdir/s3.log"

    status=0
    BM_UPLOADED_ARCHIVES="$database" FAKE_S3_LOG="$workdir/s3.log" \
    PERL5LIB="$workdir/lib:..${PERL5LIB:+:$PERL5LIB}" \
        perl ../backup-manager-upload -m s3 -h s3.amazonaws.com -u key -p secret \
            -b test -r "$repository" --s3-maxsize 1000 "$@" today \
            >/dev/null 2>&1 || status=$?
}

function recorded()
{
    grep -q "^$1 " "$database"
}

function fail()
{
    echo "t55: $*" >&2
    exit 1
}

# Successful uploads are recorded, as before.
run_upload
[[ $status -eq 0 ]] || fail "success: exit code $status"
recorded "$small" || fail "success: small archive not recorded"
recorded "$big" || fail "success: big archive not recorded"

# A rejected upload is reported and not recorded; the others still are.
FAKE_S3_MODE=fail FAKE_S3_MATCH='^host-small' run_upload
[[ $status -eq 22 ]] || fail "fail: exit code $status"
recorded "$small" && fail "fail: rejected archive recorded"
recorded "$big" || fail "fail: big archive not recorded"

# A chunk whose upload dies is reported, the archive is not recorded and
# the chunks are still removed.
FAKE_S3_MODE=die FAKE_S3_MATCH='^host-big.*-split-ab$' run_upload
[[ $status -eq 22 ]] || fail "die: exit code $status"
recorded "$big" && fail "die: failed archive recorded"
recorded "$small" || fail "die: small archive not recorded"
if ls "$big"-split-* >/dev/null 2>&1; then
    fail "die: chunks left behind"
fi

# An upload that claims success but never reaches the bucket is reported
# and not recorded.
FAKE_S3_MODE=lose FAKE_S3_MATCH='^host-small' run_upload
[[ $status -eq 22 ]] || fail "lose: exit code $status"
recorded "$small" && fail "lose: lost archive recorded"
recorded "$big" || fail "lose: big archive not recorded"

# In a bucket bigger than one listing page, the uploads are confirmed and
# the old archives purged even when they are not on the first page.
FAKE_S3_PREFILL="aaa-1 aaa-2 aaa-3 zzz-old.20000101.tar" BM_ARCHIVE_TTL=5 \
    run_upload --s3-purge
[[ $status -eq 0 ]] || fail "pages: exit code $status"
recorded "$small" || fail "pages: small archive not recorded"
recorded "$big" || fail "pages: big archive not recorded"
grep -q "^delete zzz-old.20000101.tar$" "$workdir/s3.log" \
    || fail "pages: old archive beyond the first page not purged"

# Same without list_all(): list() is paged by hand.
FAKE_S3_NO_LIST_ALL=1 FAKE_S3_PREFILL="aaa-1 aaa-2 aaa-3 zzz-old.20000101.tar" \
    BM_ARCHIVE_TTL=5 run_upload --s3-purge
[[ $status -eq 0 ]] || fail "paged list: exit code $status"
recorded "$small" || fail "paged list: small archive not recorded"
recorded "$big" || fail "paged list: big archive not recorded"
grep -q "^delete zzz-old.20000101.tar$" "$workdir/s3.log" \
    || fail "paged list: old archive beyond the first page not purged"

# When the uploads cannot be confirmed, nothing is recorded.
FAKE_S3_LIST_DIES=1 run_upload
[[ $status -eq 22 ]] || fail "list dies: exit code $status"
recorded "$small" && fail "list dies: small archive recorded"
recorded "$big" && fail "list dies: big archive recorded"

exit 0
