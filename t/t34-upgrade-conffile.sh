#! /usr/bin/env bash

set -e

# Issue #166: contrib/upgrade-conffile.sh turns a conffile using retired keys
# and yes/no booleans into one that the sanitizer accepts, with the same
# values.

source testlib.sh
# verbose="true"
# warnings="true"

conf=$(mktemp "${TMPDIR:-/tmp}/bm-upgrade-conffile-XXXXXX")
trap 'rm -f "$conf" "$conf.tmp"' EXIT

cp confs/retired-keys.conf "$conf"
cat >> "$conf" <<'CONF'
export BM_REPOSITORY_SECURE="no"
export BM_TARBALL_OVER_SSH='no'
export BM_ARCHIVE_STRICTPURGE=yes
export BM_TARBALL_DIRECTORIES="$BM_DIRECTORIES_BLACKLIST/yes"
export BM_TARBALL_DUMPSYMLINKS="no" # follow symlinks
export BM_UPLOAD_SSH_DESTINATION="/home/$BM_UPLOAD_USER"
CONF

printf 'y\n' | PAGER=cat bash ../contrib/upgrade-conffile.sh "$conf" > /dev/null

function fail()
{
    echo "$1" >&2
    cat "$conf" >&2
    exit 1
}

grep -q 'BM_REPOSITORY_SECURE="false"' "$conf" || fail "no was not replaced"
grep -q "BM_TARBALL_OVER_SSH='false'" "$conf" || fail "'no' was not replaced"
grep -q 'BM_ARCHIVE_STRICTPURGE=true' "$conf" || fail "yes was not replaced"
grep -q 'BM_TARBALL_DIRECTORIES="$BM_TARBALL_BLACKLIST/yes"' "$conf" || fail "A value was changed"
grep -q 'BM_TARBALL_DUMPSYMLINKS="false" # follow symlinks' "$conf" || fail "no followed by a comment was not replaced"
[[ "$(grep -c 'BM_UPLOAD_SSH_DESTINATION=' "$conf")" -eq 1 ]] || fail "A line referencing BM_UPLOAD_USER was duplicated"
grep -q 'BM_UPLOAD_SSH_DESTINATION="/home/$BM_UPLOAD_SSH_USER"' "$conf" || fail "A reference to BM_UPLOAD_USER was not renamed"

status=0
output=$(
    source confs/base.conf
    source "$conf"
    source $locallib/sanitize.sh
    echo "ttl=$BM_ARCHIVE_TTL"
    echo "root=$BM_REPOSITORY_ROOT"
    echo "method=$BM_UPLOAD_METHOD"
    echo "destination=$BM_UPLOAD_DESTINATION"
    echo "ssh_user=$BM_UPLOAD_SSH_USER"
    echo "ftp_user=$BM_UPLOAD_FTP_USER"
    echo "ftp_password=$BM_UPLOAD_FTP_PASSWORD"
    echo "ftp_purge=$BM_UPLOAD_FTP_PURGE"
    echo "repository_user=$BM_REPOSITORY_USER"
    echo "ssh_destination=$BM_UPLOAD_SSH_DESTINATION"
) || status=$?
[[ "$status" -eq 0 ]] || fail "The upgraded conffile was refused: $output"

for expected in "ttl=90" "root=./repository" "method=ftp" "destination=/backups" \
                "ssh_user=backup" "ftp_user=backup" "ftp_password=secret" \
                "ftp_purge=true" "repository_user=backup" \
                "ssh_destination=/home/backup"; do
    [[ "$output" == *"$expected"* ]] || fail "Expected $expected in: $output"
done

exit 0
