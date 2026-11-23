#! /usr/bin/env bash

set -e

# Encrypted tarballs are built through "tar | gpg". Both exit codes must
# be classified: tar exit 1 commits the archive, tar exit 2 and any gpg
# failure do not. Fake tar and gpg wrappers drive the exit codes, so the
# test does not need a real gpg key.
source testlib.sh
source confs/base.conf
source confs/tarball.conf

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD/testdir"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_ENCRYPTION_METHOD="gpg"
export BM_ENCRYPTION_RECIPIENT="0x00000000"
source $locallib/sanitize.sh

fakebin=$(mktemp -d)
real_tar="$tar"
cat > "$fakebin/tar" <<EOF
#!/bin/bash
"$real_tar" "\$@" || exit \$?
exit \${FAKE_TAR_EXIT:-0}
EOF
cat > "$fakebin/gpg" <<'EOF'
#!/bin/bash
cat
exit ${FAKE_GPG_EXIT:-0}
EOF
chmod +x "$fakebin/tar" "$fakebin/gpg"
tar="$fakebin/tar"
gpg="$fakebin/gpg"

function clean() {
    rm -rf testdir "$BM_ARCHIVE_ROOT"
}

function finish() {
    clean
    rm -rf "$fakebin"
    exit "$1"
}

function is_committed() {
    [[ -f "$MD5FILE" ]] && grep -qF "  $(basename "$archive")" "$MD5FILE"
}

# run_case <tar exit> <gpg exit>
function run_case() {
    clean
    mkdir -p testdir/dir1
    cat /etc/passwd > testdir/dir1/file1
    create_directories
    export FAKE_TAR_EXIT="$1"
    export FAKE_GPG_EXIT="$2"
    make_archives
}

bm_init_env
bm_init_today

name=$(get_dir_name "$PWD/testdir" long)
archive="$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz.gpg"

# tar exit 1, gpg ok: committed
run_case 1 0
[[ -e "$archive" ]] || finish 10
is_committed || finish 11

# tar exit 2, gpg ok: not committed
run_case 2 0
is_committed && finish 12

# tar ok, gpg failed: not committed
run_case 0 2
is_committed && finish 13

finish 0
