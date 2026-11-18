#! /usr/bin/env bash

set -e

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf

export BM_REPOSITORY_ROOT="$PWD/spaced repo"
export BM_BURNING_METHOD="DVD"
export BM_BURNING_DEVICE="/dev/null"
export BM_BURNING_MAXSIZE="650"
export BM_BURNING_CHKMD5="false"
source $locallib/sanitize.sh

fake_bin_dir=$(mktemp -d /tmp/bm-fake-bin.XXXXXX)
export BM_TEST_GROWISOFS_ARGS="$fake_bin_dir/args"

function clean()
{
    rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo" "$fake_bin_dir"
}

bm_init_env
bm_init_today
rm -rf "$PWD/spaced repo" "$PWD/spaced" "$PWD/repo"
create_directories
BM__BURNING_DATE="$TODAY"

# a fake growisofs that records one argument per line
cat > "$fake_bin_dir/growisofs" <<'EOS'
#!/bin/sh
for arg in "$@"; do printf '%s\n' "$arg"; done > "$BM_TEST_GROWISOFS_ARGS"
EOS
chmod +x "$fake_bin_dir/growisofs"
growisofs="$fake_bin_dir/growisofs"

first="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-etc.$TODAY.txt"
second="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-usr.$TODAY.txt"
# 600kB each: one fits in a 1M medium, both do not
head -c 600000 /dev/zero > "$first"
head -c 600000 /dev/zero > "$second"
ln -s "$first" "$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-link.$TODAY.txt"

# 1. find_what_to_burn keeps regular files, one array element per path
find_what_to_burn "$BM_REPOSITORY_ROOT"/*"$BM__BURNING_DATE"*
[[ ${#what_to_burn[@]} -eq 2 ]] || { clean; exit 10; }
[[ "${what_to_burn[0]}" = "$first" ]] || { clean; exit 11; }
[[ "${what_to_burn[1]}" = "$second" ]] || { clean; exit 12; }

# 2. burn_session hands each path to growisofs as one argument
burn_session 1 1 "${what_to_burn[@]}"
grep -qxF "$first" "$BM_TEST_GROWISOFS_ARGS" || { clean; exit 13; }
grep -qxF "$second" "$BM_TEST_GROWISOFS_ARGS" || { clean; exit 14; }

# 3. one file per medium: two index files, each with one full path
BM_BURNING_MAXSIZE="1"
__build_indexes_from_target "${what_to_burn[@]}"
[[ ${#indexes[@]} -eq 2 ]] || { clean; exit 15; }
[[ "$(cat "${indexes[0]}")" = "$first" ]] || { clean; exit 16; }
[[ "$(cat "${indexes[1]}")" = "$second" ]] || { clean; exit 17; }

# 4. burning from an index file keeps the spaced path whole
__burn_session_from_file "${indexes[1]}" 2 2
grep -qxF "$second" "$BM_TEST_GROWISOFS_ARGS" || { clean; exit 18; }

clean
exit 0
