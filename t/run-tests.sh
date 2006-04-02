#!/bin/sh

set -e

function count()
{
    total=$(($total + 1))
}

function test_failure()
{
    file="$1"
    nb_failure=$(($nb_failure + 1))
    echo "${c_h_red}failed${c_white}"

}

function test_success()
{
    file="$1"
    nb_success=$(($nb_success + 1))
    echo "ok"
}

# the conffile to test
if [ -f ./backup-manager.conf ]; then
    conffile="./backup-manager.conf"
    source $conffile
    source $libdir/sanitize.sh
    init_default_vars
fi

# colors
c_white="\[\033[00m\]"
c_h_red="\[\033[1;31m\]"

echo $(eval "${c_h_red}toto")

exit 

total=0
# Now process the tests
for file in t[0-9][0-9]*.sh
do
        count
        echo -n "[t $total] Running test $file: "
        
        if /bin/bash $file 2>/dev/null; then
            test_success $file
        else
            test_failure $file
        fi              
done

echo "------------------------------------------------------------------------------"
pct_success=$(($nb_success * 100 / $total))
echo "Success score: $pct_success% ($nb_success/$total)"
if [ "$nb_failure" -gt 0 ]; then
    echo "Failed tests: $nb_failure"
fi


