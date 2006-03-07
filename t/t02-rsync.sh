#!/bin/sh

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
#verbose="true"
#warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/upload-global.conf
source confs/upload-rsync.conf

# The test actions
bm_init_env
bm_init_today
create_archive_root_if_not_exists
make_archives
upload_files

# remove the stuff generated
rm -f repository/*

exit 0
