#!/bin/sh

set -e

test_failure()
{
    file="$1"
    nb_failure=$(($nb_failure + 1))
    echo "failed"
}

test_success()
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


# Now process the tests
for file in t[0-9][0-9]*.sh
do
        echo -n "Running test $file: "
        if /bin/bash $file; then
            test_success $file
        else
            test_failure $file
        fi              
done

echo "---------------------------------------------------"
echo "Failed tests:    $nb_failure"
echo "Sucessful tests: $nb_success"

