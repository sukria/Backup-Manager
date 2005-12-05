
# Load the backup-manager's library
locallib="../lib"
source $locallib/gettext.sh
source $locallib/logger.sh
source $locallib/dialog.sh
source $locallib/files.sh
source $locallib/md5sum.sh
source $locallib/backup-methods.sh
source $locallib/upload-methods.sh
source $locallib/actions.sh


libdir="../lib"
zip="/usr/bin/zip"
bzip="/usr/bin/bzip2"
gzip="/bin/gzip"
tar="/bin/tar"
rsync="/usr/bin/rsync"
mkisofs="/usr/bin/mkisofs"
growisofs="/usr/bin/growisofs"
cdrecord="/usr/bin/cdrecord"
bmu="/usr/bin/backup-manager-upload"
lockfile="/var/run/backup-manager.pid"
md5sum="/usr/bin/md5sum"
bc="/usr/bin/bc"
mysqldump="/usr/bin/mysqldump"
svnadmin="/usr/bin/svnadmin"
version="false"
force="false"
upload="false"
burn="false"
help="false"
md5check="false"
purge="false"

lockfile="test.lock"
conffile="confs/base.conf"
warnings="false"
verbose="false"
