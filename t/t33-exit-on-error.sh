#! /usr/bin/env bash

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# verbosedebug="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/tarball.conf

export BM_ARCHIVE_ROOT="repository"
export BM_ARCHIVE_METHOD="tarball"
export BM_TARBALL_DIRECTORIES="$PWD"
export BM_TARBALL_FILETYPE="tar.gz"
source $locallib/sanitize.sh

# The test actions

if [[ -e $BM_ARCHIVE_ROOT ]]; then
    rm -f $BM_ARCHIVE_ROOT/*
fi

bm_init_env
bm_init_today

create_directories

function fail()
{
    echo "$1"
    rm -rf $BM_ARCHIVE_ROOT
    exit 1
}

# A run where every archive is built exits 0, even with the key enabled.
export BM_EXIT_ON_ERROR="true"
make_archives
[[ "$(get_exit_code)" = "0" ]] || fail "successful run: expected exit code 0"

# A failing archive, followed by a method call that succeeds. The failure
# must not be forgotten when the next method resets its own counter.
BM_TARBALL_TARGETS=("$PWD/does-not-exist")
backup_method_tarball "tarball"
BM_TARBALL_TARGETS=("$PWD/confs")
backup_method_tarball "tarball"
name=$(get_dir_name "$PWD/confs" long)
[[ -e "$BM_ARCHIVE_ROOT/$BM_ARCHIVE_PREFIX$name.$TODAY.master.tar.gz" ]] ||
    fail "the second archive was not built"

# Opt-in: the default behaviour (key unset or false) is still exit code 0.
unset BM_EXIT_ON_ERROR
[[ "$(get_exit_code)" = "0" ]] || fail "key unset: expected exit code 0"
export BM_EXIT_ON_ERROR="false"
[[ "$(get_exit_code)" = "0" ]] || fail "key false: expected exit code 0"

export BM_EXIT_ON_ERROR="true"
[[ "$(get_exit_code)" = "3" ]] || fail "key true: expected exit code 3"

rm -rf $BM_ARCHIVE_ROOT
exit 0
