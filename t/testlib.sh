
# Load the backup-manager's library
locallib="../lib"
source $locallib/gettext.sh
source $locallib/logger.sh
source $locallib/dialog.sh
source $locallib/files.sh
source $locallib/md5sum.sh
source $locallib/backup-methods.sh
source $locallib/upload-methods.sh
source $locallib/burning-methods.sh
source $locallib/actions.sh

VERSION="0.7.1+svn"

# All the path we'll need
libdir="/usr/share/backup-manager"
zip="/usr/bin/zip"
bzip="/usr/bin/bzip2"
gzip="/bin/gzip"
dar="/usr/bin/dar"
tar="/bin/tar"
rsync="/usr/bin/rsync"
mkisofs="/usr/bin/mkisofs"
growisofs="/usr/bin/growisofs"
dvdrwformat="/usr/bin/dvd+rw-format"
cdrecord="/usr/bin/cdrecord"
bmu="/usr/bin/backup-manager-upload"
lockfile="/var/run/backup-manager.pid"
md5sum="/usr/bin/md5sum"
bc="/usr/bin/bc"
mysqldump="/usr/bin/mysqldump"
svnadmin="/usr/bin/svnadmin"


libdir="../lib"
bmu="../backup-manager-upload"
lockfile="$PWD/backup-manager.pid"
lockfile="$PWD/test.lock"

conffile="confs/base.conf"
version="false"
force="false"
upload="false"
burn="false"
help="false"
md5check="false"
purge="false"
warnings="false"
verbose="false"
