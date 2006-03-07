#!/bin/sh

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
export BM_ARCHIVE_METHOD="none"
export BM_UPLOAD_METHOD="none"
export BM_BURNING_METHOD="none"

# The test actions
bm_init_env
bm_init_today
create_archive_root_if_not_exists
make_archives
upload_files
burn_files

exit 0
