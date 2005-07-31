#  Backup Manager Configuration File
#
#  Global notes:

#  * Whenver you see a configuration key set to yes, you can 
#    safely change it to no. They are booleans.
#  * This configuration file is divided into sections.
#    The 'global' section is mandatory, every keys defined in 
#    this section are inherited in the other sections.
#  * There are one section per "backup method", you have to 
#    to fill the section of the chosen method.
#
##############################################################

##############################################################
# Repository - everything about where archives live
#############################################################

# Where to store the archives
export BM_REPOSITORY_ROOT="/var/archives"

# For security reasons, the archive repository and the generated 
# archives will be readable/writable by a given user/group.
# This is recommanded to set this to yes.
export BM_REPOSITORY_SECURE="yes"

# The repository will be readable/writable only by a specific 
# user:group pair if BM_REPOSITORY_SECURE is set to yes.
export BM_REPOSITORY_USER="root"
export BM_REPOSITORY_GROUP="root"

##############################################################
# Archives - let's focus on the precious tarballs...
##############################################################

# Number of days we have to keep an archive (Time To Live)
export BM_ARCHIVE_TTL="5"

# Do you want to replace duplicates by symlinks? 
# (archive-DAY is a duplicate of archive-(DAY - 1) if they 
# are both the same size).
export BM_ARCHIVE_PURGEDUPS="yes"

# Prefix of every archive on that box (default is HOSTNAME)
export BM_ARCHIVE_PREFIX="$HOSTNAME"

# The backup method to use.
export BM_ARCHIVE_METHOD="tarball"

##############################################################
# Section "TARBALL"
# - Backup method: tarball
#############################################################

# Archive filename format
# 	long  : host-full-path-to-folder.tar.gz
# 	short : parentfolder.tar.gz
export BM_TARBALL_NAMEFORMAT="long"

# Type of archives, available types are tar, tar.gz, tar.bz2, zip.
export BM_TARBALL_FILETYPE="tar.gz"

# Do you want to dereference the files pointed by symlinks ? 
# enter yes or no (yes can leed to huge archives, be careful).
export BM_TARBALL_DUMPSYMLINKS="no"

# Directories you want to backup as tarballs (separated by spaces)
export BM_TARBALL_DIRECTORIES="/etc /home"

# Files to exclude when generating tarballs
export BM_TARBALL_BLACKLIST=""

##############################################################
# Section "RSYNC"
# Backup method: rsync
#############################################################
##############################################################
# Backup method: mysql
#############################################################
##############################################################
# Backup method: pipe
#############################################################
##############################################################
# Burning system
#############################################################
##############################################################
# Upload system
#############################################################



##############################################################
# Section "UPLOAD"
# - The upload system allow you to send the archives to 
#   to remote hosts, either with FTP or SSH.
#############################################################

# The list of remote host, if you want to enable the upload
# systemn jsut put some remote hosts here (fqdn or IPs)
export BM_UPLOAD_HOSTS=""

# which protocol to use for tranfert ? (scp or ftp)
export BM_UPLOAD_MODE=""

# User for opening the remote connection
export BM_UPLOAD_USER=""

# Password, only needed for ftp transfert, scp is based on key identification.
export BM_UPLOAD_PASSWD=""

# cleans specified ftp folder before uploading (yes or no)
export BM_UPLOAD_FTPPURGE=""

# if scp mode is used, an identity file is needed
export BM_UPLOAD_KEY=""

#"/backup/upload/"
export BM_UPLOAD_DIR=""


##############################################################
# Section "BURNING" 
# - Automatic CDR/CDRW burning
#############################################################

# set this to yes if you want automatic burning.
export BM_BURNING="no"

# When the CD is burnt, it is possible to check every file's 
# MD5 checksum to see if the CD is not corrupted.
export BM_BURNING_CHKMD5="yes"

# The device to use for mounting the cdrom
export BM_BURNING_DEVICE="/dev/cdrom"

# You can force cdrecord to use a specific device
# Fill in the full path to the device to use or even
# e.g. BM_BURNING_DEVFORCED="/dev/cdrom"
# If none specified, the default cdrecord device will be used.
export BM_BURNING_DEVFORCED=""

# the method of burning archives from the list :
#  - CDRW : blanking the CDRW and burning the all 
#           ARCHIVES_REPOSITORY or only 
#           the generated archives.
#  - CDR  : burning all the ARCHIVES_REPOSITORY or 
#           only the generated archives.
export BM_BURNING_METHOD="CDRW"

# enter here the max size of your media
export BM_BURNING_MAXSIZE="700"


##############################################################
# Advanced settings, use this with care.
#############################################################

# Every output made can be sent to syslog
# set this to "yes" or "no"
export BM_LOGGER="yes"

# You can choose which facility to use
export BM_LOGGER_FACILITY="user"

# Enter here some shell script.
# It will be executed before the first action of backup-manager.
export BM_PRE_BACKUP_COMMAND=""

# Enter here some shell script.
# It will be executed after the last action of backup-manager.
export BM_POST_BACKUP_COMMAND=""

