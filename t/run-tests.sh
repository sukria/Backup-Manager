#! /usr/bin/env bash

set -e
# set -x

function count()
{
    total=$(($total + 1))
}

function test_failure()
{
    file="$1"
    nb_failure=$(($nb_failure + 1))
    echo "failed"

}

function test_success()
{
    file="$1"
    nb_success=$(($nb_success + 1))
    echo "ok"
}

# the conffile to test
if [[ -f ./backup-manager.conf ]]; then
    conffile="./backup-manager.conf"
    source $conffile
    source $libdir/sanitize.sh
    init_default_vars
fi

total=0
nb_failure=0
# Now process the tests
cd `dirname $0`
for file in t[0-9][0-9]*.sh
do
        count
        echo -n "[t $total] Running test $file: "
        
        if bash $file 2>/dev/null; then
            test_success $file
        else
            test_failure $file
        fi              
done

echo "------------------------------------------------------------------------------"
pct_success=$(($nb_success * 100 / $total))
echo "Success score: $pct_success% ($nb_success/$total)"
if [[ "$nb_failure" -gt 0 ]]; then
    echo "Failed tests: $nb_failure"
    exit 1
fi

exit 0
