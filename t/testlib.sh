
# Load the backup-manager's library
locallib="../lib"
libdir="$locallib"
source $locallib/externals.sh
source $locallib/gettext.sh
source $locallib/logger.sh
source $locallib/dialog.sh
source $locallib/files.sh
source $locallib/md5sum.sh
source $locallib/backup-methods.sh
source $locallib/upload-methods.sh
source $locallib/burning-methods.sh
source $locallib/actions.sh
source $locallib/dbus.sh

VERSION="0.7.1+svn"

# external programs (cannot be sure where the are)
zip=$(which zip) || true
bzip=$(which bzip2) || true
gzip=$(which gzip) || true
gpg=$(which gpg) || true
lzma=$(which lzma) || true
dar=$(which dar) || true
tar=$(which tar) || true
rsync=$(which rsync) || true
mkisofs=$(which mkisofs) || true
growisofs=$(which growisofs) || true
dvdrwformat=$(which dvd+rw-format) || true
cdrecord=$(which cdrecord) || true
md5sum=$(which md5sum) || true
bc=$(which bc) || true
mysqldump=$(which mysqldump) || true
svnadmin=$(which svnadmin) || true
logger=$(which logger) || true

# Find which lockfile to use
# If we are called by an unprivileged user, use a lockfile inside the user's home;
# else, use /var/run/backup-manager.lock
systemlockfile="/var/run/backup-manager.lock"
userlockfile="$HOME/.backup-manager.lock"
if [[ "$UID" != 0 ]]; then
    lockfile="$userlockfile"
else
    lockfile="$systemlockfile"
fi

libdir="../lib"
bmu="../backup-manager-upload"

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

bm_dbus_init

