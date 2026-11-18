#! /usr/bin/env bash

set -e

# Bug #146: the MySQL/MariaDB password set in BM_MYSQL_ADMINPASS must not be
# overridden by the [client] section of the user's ~/.my.cnf.

source testlib.sh
# verbose="true"
# warnings="true"

source confs/base.conf
source confs/mysql.conf
export BM_REPOSITORY_ROOT="$PWD/repository"
export BM_MYSQL_FILETYPE="none"
export BM_MYSQL_SEPARATELY="true"
export BM_MYSQL_DATABASES="__ALL__"
export BM_MYSQL_DBEXCLUDE=""
source $locallib/sanitize.sh
bm_init_env
bm_init_today

fakedir="$PWD/fake-mysql"
rm -rf $fakedir $BM_REPOSITORY_ROOT
mkdir -p $fakedir/home $fakedir/bin

# A fake MySQL client/dump binary that resolves the password the way MySQL
# does: --defaults-file reads only that file, --defaults-extra-file reads it
# and then ~/.my.cnf, which wins for keys set in both.
cat > $fakedir/bin/fake-mysql <<'EOF'
#!/usr/bin/env bash
case "$1" in
    --defaults-file=*) files=("${1#*=}"); shift ;;
    --defaults-extra-file=*) files=("${1#*=}" "$HOME/.my.cnf"); shift ;;
    *) files=("$HOME/.my.cnf") ;;
esac
password=""
for f in "${files[@]}"; do
    if [[ -f "$f" ]] && grep -q '^password=' "$f"; then
        password=$(sed -n 's/^password=//p' "$f" | tail -n 1 | tr -d '"')
    fi
done
if [[ "$password" != "$FAKE_MYSQL_PASSWORD" ]]; then
    echo "Access denied (using password: $password)" >&2
    exit 1
fi
if [[ "$*" == *"show databases"* ]]; then
    echo "testdb"
else
    echo "-- dump of ${@: -1}"
fi
EOF
chmod 755 $fakedir/bin/fake-mysql
mysqldump="$fakedir/bin/fake-mysql"
mysql="$fakedir/bin/fake-mysql"

expected="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-mysql-testdb.$TODAY.sql"

function run_mysql_backup()
{
    rm -rf $BM_REPOSITORY_ROOT
    create_directories
    ( HOME="$fakedir/home"; backup_method_mysql "mysql" )
    if [[ ! -s $expected ]]; then
        warning "file $expected does not exist"
        rm -rf $fakedir $BM_REPOSITORY_ROOT
        exit 10
    fi
}

# 1. ~/.my.cnf holds other credentials: the configured password must be used.
export FAKE_MYSQL_PASSWORD="bm-secret"
export BM_MYSQL_ADMINPASS="bm-secret"
printf '[client]\nuser=someoneelse\npassword=other-secret\n' > $fakedir/home/.my.cnf
run_mysql_backup

# 2. No BM_MYSQL_ADMINPASS: the password from ~/.my.cnf is still honoured.
export FAKE_MYSQL_PASSWORD="mycnf-secret"
export BM_MYSQL_ADMINPASS=""
printf '[client]\npassword=mycnf-secret\n' > $fakedir/home/.my.cnf
run_mysql_backup

# 3. An existing conffile holding a password wins over ~/.my.cnf.
export FAKE_MYSQL_PASSWORD="conffile-secret"
printf '[client]\npassword=conffile-secret\n' > $fakedir/home/.backup-manager_my.cnf
run_mysql_backup

# 4. An existing conffile with an empty password lets ~/.my.cnf provide it.
export FAKE_MYSQL_PASSWORD="mycnf-secret"
printf '[client]\npassword=""\n' > $fakedir/home/.backup-manager_my.cnf
run_mysql_backup

rm -rf $fakedir $BM_REPOSITORY_ROOT
exit 0
