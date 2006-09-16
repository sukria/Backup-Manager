#!/bin/bash

set -e

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
source confs/upload-global.conf
source confs/upload-rsync.conf
source $locallib/sanitize.sh

# The test actions
bm_init_env
bm_init_today
create_directories
make_archives
upload_files


# same test without SSH keys
export BM_UPLOAD_SSH_HOST="localhost"
export BM_UPLOAD_SSH_USER=""
export BM_UPLOAD_SSH_KEY=""

make_archives
upload_files

# remove the stuff generated
# rm -rf repository

exit 0
