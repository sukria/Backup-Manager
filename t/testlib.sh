
# Load the backup-manager's library
locallib="../lib"
libdir="$locallib"
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

# external programs (cannot be sure where the are)
zip=$(which zip)
bzip=$(which bzip2)
gzip=$(which gzip)
gpg=$(which gpg)
lzma=$(which lzma)
dar=$(which dar)
tar=$(which tar)
rsync=$(which rsync)
mkisofs=$(which mkisofs)
growisofs=$(which growisofs)
dvdrwformat=$(which dvd+rw-format)
cdrecord=$(which cdrecord)
md5sum=$(which md5sum)
bc=$(which bc)
mysqldump=$(which mysqldump)
svnadmin=$(which svnadmin)
logger=$(which logger)

# Find which lockfile to use
# If we are called by an unprivileged user, use a lockfile inside the user's home;
# else, use /var/run/backup-manager.lock
systemlockfile="/var/run/backup-manager.lock"
userlockfile="$HOME/.backup-manager.lock"
if [ "$UID" != 0 ]; then
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
