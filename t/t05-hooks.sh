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
export BM_PRE_BACKUP_COMMAND="/bin/true"
export BM_POST_BACKUP_COMMAND="echo true"
source $locallib/sanitize.sh

# The test actions
bm_init_env
bm_init_today
exec_pre_command
exec_post_command

exit 0
