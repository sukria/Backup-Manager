#! /usr/bin/env bash

set -e

# Regression test for issue #130: tar exit code 1 ("file changed as we
# read it") must commit the archive and record its md5 hash; exit code 2
# must still be treated as an error.
source testlib.sh
source confs/base.conf
source confs/tarball.conf

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD/testdir"
export BM_TARBALL_FILETYPE="tar.gz"
source $locallib/sanitize.sh

fakebin=$(mktemp -d)
real_tar="$tar"
cat > "$fakebin/tar" <<EOF
#!/bin/bash
"$real_tar" "\$@" || exit \$?
exit \${FAKE_TAR_EXIT:-0}
EOF
chmod +x "$fakebin/tar"
tar="$fakebin/tar"

function clean() {
    rm -rf testdir "$BM_ARCHIVE_ROOT"
}

bm_init_env
bm_init_today

clean
mkdir -p testdir/dir1
cat /etc/passwd > testdir/dir1/file1

name=$(get_dir_name "$PWD/testdir" long)
archive="$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz"

# exit 1: archive kept and committed
create_directories
export FAKE_TAR_EXIT=1
make_archives
[[ -e "$archive" ]] || { clean; rm -rf "$fakebin"; exit 10; }
grep -qF "  $(basename "$archive")" "$MD5FILE" || { clean; rm -rf "$fakebin"; exit 11; }

# exit 2: still an error, never committed
clean
create_directories
export FAKE_TAR_EXIT=2
make_archives
if [[ -f "$MD5FILE" ]] && grep -qF "  $(basename "$archive")" "$MD5FILE"; then
    clean; rm -rf "$fakebin"; exit 12
fi

clean
rm -rf "$fakebin"
exit 0
