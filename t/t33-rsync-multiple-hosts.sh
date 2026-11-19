#! /usr/bin/env bash

# Make sure the rsync upload method runs one rsync per configured host
# when more than one host is given (issue #172).

set -e

source testlib.sh

workdir=$(mktemp -d "${TMPDIR:-/tmp}/bm-t33-XXXXXX")
trap 'rm -rf "$workdir"' EXIT

# A fake rsync that records the destination it is given.
calls="$workdir/rsync-calls"
cat > "$workdir/rsync" <<EOF2
#! /usr/bin/env bash
for last; do :; done
echo "\$last" >> "$calls"
EOF2
chmod +x "$workdir/rsync"
rsync="$workdir/rsync"

export BM_TEMP_DIR="$workdir"
export BM_UPLOAD_RSYNC_DIRECTORIES="$workdir"
export BM_UPLOAD_RSYNC_DESTINATION="/backups"
export BM_UPLOAD_SSH_USER="bmtest"
export BM_UPLOAD_SSH_KEY="$workdir/key"

# Several hosts in BM_UPLOAD_RSYNC_HOSTS
export BM_UPLOAD_HOSTS=""
export BM_UPLOAD_RSYNC_HOSTS="host1 host2"
bm_upload_rsync >/dev/null 2>&1

[[ "$(cat "$calls")" == "bmtest@host1:/backups/
bmtest@host2:/backups/" ]]

# Hosts coming from both BM_UPLOAD_HOSTS and BM_UPLOAD_RSYNC_HOSTS
rm -f "$calls"
export BM_UPLOAD_HOSTS="host1"
export BM_UPLOAD_RSYNC_HOSTS="host2 host3"
bm_upload_rsync >/dev/null 2>&1

[[ "$(cat "$calls")" == "bmtest@host1:/backups/
bmtest@host2:/backups/
bmtest@host3:/backups/" ]]

exit 0
