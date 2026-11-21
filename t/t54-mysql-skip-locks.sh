#! /usr/bin/env bash

set -e

# Issue #54: BM_MYSQL_SKIP_LOCKS dumps without locking tables and leaves the
# command line untouched when unset. BM_MYSQL_SAFEDUMPS is deprecated: it
# keeps its behaviour but triggers a warning.

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf
source confs/mysql.conf
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_MYSQL_FILETYPE="none"
export BM_MYSQL_SEPARATELY="false"
export BM_MYSQL_DATABASES="testdb"
export BM_MYSQL_ADMINPASS="bm-secret"
export BM_MYSQL_EXTRA_OPTIONS="--hex-blob"
unset BM_MYSQL_SAFEDUMPS
unset BM_MYSQL_SKIP_LOCKS
source $locallib/sanitize.sh
bm_init_env
bm_init_today

fakedir="$PWD/fake-mysql-locks"
rm -rf $fakedir $BM_REPOSITORY_ROOT
mkdir -p $fakedir/home $fakedir/bin

# A fake dump binary that records its arguments, one per line.
cat > $fakedir/bin/fake-dump <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_ARGS_FILE"
echo "-- dump of ${@: -1}"
EOF
chmod 755 $fakedir/bin/fake-dump
export FAKE_ARGS_FILE="$fakedir/args"
mysqldump="$fakedir/bin/fake-dump"
mariadbdump="$fakedir/bin/fake-dump"

function fail()
{
    echo "FAIL: $1" >&2
    rm -rf $fakedir $BM_REPOSITORY_ROOT
    exit 10
}

# Runs the method and stores its warnings in $output.
function run_dump()
{
    method="$1"
    rm -rf $BM_REPOSITORY_ROOT $FAKE_ARGS_FILE
    create_directories
    output=$( HOME="$fakedir/home"; warnings="true"; backup_method_$method "$method" 2>&1 )
    [[ -s "$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${method}-testdb.$TODAY.sql" ]] \
        || fail "no $method dump produced"
}

# Prints the 1-based position of an argument, or nothing.
function argpos()
{
    grep -nxF -- "$1" "$FAKE_ARGS_FILE" | head -n 1 | cut -d: -f1
}

for method in mysql mariadb; do
    # 1. Nothing set: same command line as before, no new warning.
    unset BM_MYSQL_SAFEDUMPS BM_MYSQL_SKIP_LOCKS
    run_dump $method
    [[ -z "$(argpos --opt)" ]] || fail "$method: --opt added when SAFEDUMPS is unset"
    [[ -z "$(argpos --single-transaction)" ]] || fail "$method: --single-transaction added by default"
    [[ -z "$(argpos --skip-lock-tables)" ]] || fail "$method: --skip-lock-tables added by default"
    [[ "$output" != *"BM_MYSQL_SAFEDUMPS"* ]] || fail "$method: SAFEDUMPS warning while unset"

    # 2. SAFEDUMPS=true (the old template default): --opt kept, deprecation warned.
    export BM_MYSQL_SAFEDUMPS="true"
    run_dump $method
    [[ -n "$(argpos --opt)" ]] || fail "$method: --opt missing with SAFEDUMPS=true"
    [[ -z "$(argpos --skip-lock-tables)" ]] || fail "$method: --skip-lock-tables added with SAFEDUMPS=true"
    [[ "$output" == *"BM_MYSQL_SAFEDUMPS"*"deprecated"* ]] || fail "$method: no deprecation warning"

    # 3. SKIP_LOCKS=false: identical to unset.
    export BM_MYSQL_SKIP_LOCKS="false"
    run_dump $method
    [[ -z "$(argpos --single-transaction)" ]] || fail "$method: --single-transaction added when false"
    [[ -z "$(argpos --skip-lock-tables)" ]] || fail "$method: --skip-lock-tables added when false"

    # 4. SKIP_LOCKS=true: both switches, after --opt and before the extra options.
    export BM_MYSQL_SKIP_LOCKS="true"
    run_dump $method
    p_opt=$(argpos --opt)
    p_trx=$(argpos --single-transaction)
    p_skip=$(argpos --skip-lock-tables)
    p_extra=$(argpos --hex-blob)
    [[ -n "$p_trx" && -n "$p_skip" ]] || fail "$method: skip-locks switches missing"
    [[ $p_opt -lt $p_trx && $p_opt -lt $p_skip ]] || fail "$method: skip-locks switches must follow --opt"
    [[ $p_skip -lt $p_extra && $p_trx -lt $p_extra ]] || fail "$method: extra options must stay last"

    # 5. SKIP_LOCKS=true with --lock-all-tables in the extra options: refused.
    for conflict in "--lock-all-tables" "-x" "--hex-blob --lock-all-tables=1"; do
        export BM_MYSQL_EXTRA_OPTIONS="$conflict"
        rm -rf $BM_REPOSITORY_ROOT $FAKE_ARGS_FILE
        create_directories
        if ( HOME="$fakedir/home"; backup_method_$method "$method" ) >/dev/null 2>&1; then
            fail "$method: '$conflict' with BM_MYSQL_SKIP_LOCKS=true was accepted"
        fi
        [[ ! -e $FAKE_ARGS_FILE ]] || fail "$method: dump ran despite '$conflict'"
    done
    export BM_MYSQL_EXTRA_OPTIONS="--hex-blob"

    # 6. SAFEDUMPS=false without SKIP_LOCKS: unchanged dump, warning names the new key.
    export BM_MYSQL_SAFEDUMPS="false"
    unset BM_MYSQL_SKIP_LOCKS
    run_dump $method
    [[ -z "$(argpos --opt)" ]] || fail "$method: SAFEDUMPS=false must still omit --opt"
    [[ -z "$(argpos --skip-lock-tables)" ]] || fail "$method: SAFEDUMPS=false must not change locking"
    [[ "$output" == *"does not disable table locking"*"BM_MYSQL_SKIP_LOCKS"* ]] \
        || fail "$method: no warning pointing to BM_MYSQL_SKIP_LOCKS"

    # 7. SAFEDUMPS=false with SKIP_LOCKS=true: no locking warning.
    export BM_MYSQL_SKIP_LOCKS="true"
    run_dump $method
    [[ -n "$(argpos --skip-lock-tables)" ]] || fail "$method: --skip-lock-tables missing with SAFEDUMPS=false"
    [[ "$output" != *"does not disable table locking"* ]] || fail "$method: spurious locking warning"
done

rm -rf $fakedir $BM_REPOSITORY_ROOT
exit 0
