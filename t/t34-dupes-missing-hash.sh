#! /usr/bin/env bash

set -e

# Regression test for issue #130: an older archive with no entry in the
# md5 database must still be deduplicated, without persisting its hash.
source testlib.sh
source confs/base.conf
source confs/tarball.conf

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD/testdir"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_ARCHIVE_PURGEDUPS="true"
export BM_TARBALLINC_MASTERDATEVALUE="999"
source $locallib/sanitize.sh

function clean() {
    rm -rf testdir "$BM_ARCHIVE_ROOT"
}

bm_init_env
bm_init_today
YESTERDAY=$(date +%Y%m%d --date '1 days ago')
TODAY=$YESTERDAY

clean
mkdir -p testdir/dir1
cat /etc/passwd > testdir/dir1/file1

create_directories
make_archives

name=$(get_dir_name "$PWD/testdir" long)
old="$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$YESTERDAY.master.tar.gz"
[[ -e "$old" ]] || { clean; exit 20; }

# Simulate an archive left without a hash (pre-fix tar exit 1)
grep -vF "  $(basename "$old")" "$MD5FILE" > "$MD5FILE.tmp" || true
mv "$MD5FILE.tmp" "$MD5FILE"

# Show warnings so the run below can be checked for the old message.
warnings="true"
bm_init_today
output=$(make_archives 2>&1)
warnings="false"

[[ -L "$old" ]] || { clean; exit 1; }
if grep -qF "  $(basename "$old")" "$MD5FILE"; then
    clean; exit 2
fi
if [[ "$output" == *"md5 hash of file"* ]]; then
    clean; exit 3
fi

clean
exit 0
