#! /usr/bin/env bash

set -e

# Issue #166: a retired configuration key must stop the run with a message
# naming its replacement, instead of being silently ignored while the new key
# falls back on its default value (BM_MAX_TIME_TO_LIVE="90" ignored means
# BM_ARCHIVE_TTL="5", and a purge of everything older than five days).

source testlib.sh
# verbose="true"
# warnings="true"

# Without gettext, lib/gettext-dummy.sh drops the double quotes of the
# messages, so the checks below do not rely on them.

# Sources the sanitizer in a subshell, with the base conffile plus the given
# assignments, and stores its output in $output and its exit code in $status.
function run_sanitize()
{
    status=0
    output=$(
        source confs/base.conf
        for assignment in "$@"; do
            export "$assignment"
        done
        source $locallib/sanitize.sh
    ) || status=$?
}

function fail()
{
    echo "$1" >&2
    echo "output: $output" >&2
    exit 1
}

# Every key of the 0.5.x conffile is refused, one at a time.
retired_keys=$(sed -n 's/^export \([A-Z_]*\)=.*/\1/p' confs/retired-keys.conf)
[[ -n "$retired_keys" ]] || fail "No key found in confs/retired-keys.conf"
for key in $retired_keys; do
    line=$(grep "^export $key=" confs/retired-keys.conf)
    eval "value=${line#*=}"
    run_sanitize "$key=$value"
    [[ "$status" -ne 0 ]] || fail "$key was accepted"
    [[ "$output" == *"$key"*"was removed in Backup Manager"* ]] || fail "$key: no removal message"
    [[ "$output" == *"contrib/upgrade-conffile.sh"* ]] || fail "$key: no pointer to the upgrade script"
done

# The fixture covers every retired key, so t34 checks that the upgrade script
# renames all of them.
table_keys=$(
    source confs/base.conf
    source $locallib/sanitize.sh
    for entry in "${BM__RETIRED_CONFKEYS[@]}"; do
        echo "${entry%% *}"
    done
)
[[ "$(echo "$table_keys" | sort)" == "$(echo "$retired_keys" | sort)" ]] || fail "confs/retired-keys.conf does not match BM__RETIRED_CONFKEYS"

# The message names the replacement.
run_sanitize "BM_MAX_TIME_TO_LIVE=90"
[[ "$output" == *"rename it to "*"BM_ARCHIVE_TTL"* ]] || fail "BM_MAX_TIME_TO_LIVE: replacement not named"

# A key split in two names both replacements.
run_sanitize "BM_UPLOAD_USER=backup"
[[ "$output" == *"one of BM_UPLOAD_SSH_USER, BM_UPLOAD_FTP_USER"* ]] || fail "BM_UPLOAD_USER: replacements not named"

# Refused even when the key used to be read only behind another key.
run_sanitize "BM_REPOSITORY_SECURE=false" "BM_USER=nobody"
[[ "$status" -ne 0 ]] || fail "BM_USER accepted with BM_REPOSITORY_SECURE=false"
run_sanitize "BM_UPLOAD_PASSWD=secret"
[[ "$status" -ne 0 ]] || fail "BM_UPLOAD_PASSWD accepted without BM_UPLOAD_MODE"

# Refused even when the new key is set too.
run_sanitize "BM_ARCHIVE_TTL=5" "BM_MAX_TIME_TO_LIVE=90"
[[ "$status" -ne 0 ]] || fail "BM_MAX_TIME_TO_LIVE accepted alongside BM_ARCHIVE_TTL"

# The whole 0.5.x conffile is refused before any default value is applied.
status=0
output=$(
    source confs/base.conf
    source confs/retired-keys.conf
    source $locallib/sanitize.sh
    echo "BM_ARCHIVE_TTL=$BM_ARCHIVE_TTL"
) || status=$?
[[ "$status" -ne 0 ]] || fail "The 0.5.x conffile was accepted"
[[ "$output" != *"BM_ARCHIVE_TTL="* ]] || fail "The run went on with the 0.5.x conffile"

# yes/no booleans are refused, naming the expected value.
run_sanitize "BM_ARCHIVE_PURGEDUPS=yes"
[[ "$status" -ne 0 ]] || fail "yes boolean accepted"
[[ "$output" == *"BM_ARCHIVE_PURGEDUPS is set to "*"yes"*"Set it to "*"true"* ]] || fail "yes boolean: bad message"
run_sanitize "BM_TARBALL_DUMPSYMLINKS=no"
[[ "$status" -ne 0 ]] || fail "no boolean accepted"
[[ "$output" == *"BM_TARBALL_DUMPSYMLINKS is set to "*"no"*"Set it to "*"false"* ]] || fail "no boolean: bad message"

# Including when the boolean is not exported.
status=0
output=$(
    source confs/base.conf
    BM_REPOSITORY_SECURE=yes
    source $locallib/sanitize.sh
) || status=$?
[[ "$status" -ne 0 ]] || fail "Unexported yes boolean accepted"

# A value containing yes or no is not a boolean.
run_sanitize "BM_POST_BACKUP_COMMAND=notify BM_VERBOSE=yes"
[[ "$status" -eq 0 ]] || fail "A value containing yes was refused"

# A retired key set to an empty value is not in use.
run_sanitize "BM_MAX_TIME_TO_LIVE="
[[ "$status" -eq 0 ]] || fail "An empty retired key was refused"

# A deprecated key is still honoured, with a warning naming both keys.
status=0
output=$(
    warnings="true"
    source confs/base.conf
    export BM_DIRECTORIES="/etc /boot"
    source $locallib/sanitize.sh
    echo "targets=${BM_TARBALL_TARGETS[*]}"
) || status=$?
[[ "$status" -eq 0 ]] || fail "The deprecated BM_DIRECTORIES was refused"
[[ "$output" == *"targets=/etc /boot"* ]] || fail "BM_DIRECTORIES was not honoured"
[[ "$output" == *"BM_DIRECTORIES"*"is deprecated, you should rename it "*"BM_TARBALL_DIRECTORIES"* ]] || fail "BM_DIRECTORIES: no deprecation warning"

# The current conffile keeps working.
run_sanitize
[[ "$status" -eq 0 ]] || fail "The base conffile was refused"

exit 0
