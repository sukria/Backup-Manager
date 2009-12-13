#!/bin/bash

set -e

export BM_TEST_EXIT_CODE_EXPECTED=10

# Each test script should include testlib.sh
source testlib.sh
# When the test is ready, set this to false for nice outputs.
# if you want to see what happens, use those flags
# verbose="true"
# warnings="true"

# The conffile part of the test, see confs/* for details.
source confs/base.conf
export BM_PRE_BACKUP_COMMAND="/NON_EXISTANT_FILE.pre.sh"
export BM_POST_BACKUP_COMMAND="NON_EXISTANT_FILE.post.sh"
source $locallib/sanitize.sh

# The test actions
bm_init_env
bm_init_today
exec_pre_command
# FIXME: try to catch the exit 10 that will be thrown
exec_post_command
exit 0
