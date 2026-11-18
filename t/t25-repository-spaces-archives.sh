#! /usr/bin/env bash

set -e

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf
source confs/tarball.conf

export BM_REPOSITORY_ROOT="$PWD/spaced repo"
export BM_REPOSITORY_SECURE="true"
export BM_REPOSITORY_USER="$(id -un)"
export BM_REPOSITORY_GROUP="$(id -gn)"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_FILETYPE="tar.gz"
export BM_TARBALL_DIRECTORIES="$PWD/testdir-spaces"
export BM_TARBALLINC_MASTERDATETYPE="weekly"
source $locallib/sanitize.sh

function clean()
{
    rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo" "$PWD/testdir-spaces"
}

function reset_repository()
{
    rm -rf "$BM_REPOSITORY_ROOT"
    create_directories
}

bm_init_env
bm_init_today
clean
mkdir -p testdir-spaces/dir1
cp /etc/passwd testdir-spaces/dir1/file1
name=$(get_dir_name "$PWD/testdir-spaces" long)
yesterday=$(date +%Y%m%d --date '1 days ago')

# 1. plain tar.gz tarball
create_directories
make_archives
archive="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz"
[[ -f "$archive" ]] || { clean; exit 10; }
tar tzf "$archive" | grep -q "dir1/file1" || { clean; exit 11; }
grep -qF "  $(basename "$archive")" "$MD5FILE" || { clean; exit 12; }
[[ "$(stat -c %a "$MD5FILE")" = "660" ]] || { clean; exit 13; }

# 2. tarball-incremental: master made "yesterday", incremental today
reset_repository
export BM_ARCHIVE_METHOD="tarball-incremental"
export BM_TARBALLINC_MASTERDATEVALUE="$(date +'%w')"
TODAY="$yesterday"
make_archives
[[ -f "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$name.$yesterday.master.tar.gz" ]] || { clean; exit 20; }
[[ -f "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$name.incremental.bin" ]] || { clean; exit 21; }

cp /etc/group testdir-spaces/dir1/file2
bm_init_today
export BM_TARBALLINC_MASTERDATEVALUE="999"
make_archives
[[ -f "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.tar.gz" ]] || { clean; exit 22; }

# 3. pipe method (goes through __exec_meta_command)
reset_repository
export BM_ARCHIVE_METHOD="pipe"
BM_PIPE_COMMAND[0]="cat /etc/passwd"
BM_PIPE_NAME[0]="passwd"
BM_PIPE_FILETYPE[0]="txt"
BM_PIPE_COMPRESS[0]="gzip"
BM_PIPE_COMMAND[1]="cat /etc/group"
BM_PIPE_NAME[1]="group"
BM_PIPE_FILETYPE[1]="txt"
BM_PIPE_COMPRESS[1]=""
if [[ -x "$zstd" ]]; then
    BM_PIPE_COMMAND[2]="cat /etc/hostname"
    BM_PIPE_NAME[2]="hostname"
    BM_PIPE_FILETYPE[2]="txt"
    BM_PIPE_COMPRESS[2]="zstd"
fi
make_archives
gz_file="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-passwd.$TODAY.txt.gz"
txt_file="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-group.$TODAY.txt"
[[ -f "$gz_file" ]] || { clean; exit 30; }
[[ -f "$txt_file" ]] || { clean; exit 31; }
gzip -dc "$gz_file" | cmp -s - /etc/passwd || { clean; exit 32; }
cmp -s "$txt_file" /etc/group || { clean; exit 33; }
if [[ -x "$zstd" ]]; then
    [[ -f "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-hostname.$TODAY.txt.zst" ]] || { clean; exit 34; }
fi

# 4. dar (only if installed)
if [[ -x "$dar" ]]; then
    reset_repository
    export BM_ARCHIVE_METHOD="tarball"
    export BM_TARBALL_FILETYPE="dar"
    make_archives
    [[ -f "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.1.dar" ]] || { clean; exit 40; }
fi

clean
exit 0
