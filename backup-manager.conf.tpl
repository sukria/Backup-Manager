#    Backup Manager Configuration File
#
#  Global notes:
#  Whenver you see aconfiguration key set to yes, you can 
# safely change it to no. They are booleans.
#
##############################################################


##############################################################
# Archives
##############################################################

# Archive filename format
# 	long  : host-full-path-to-folder.tar.gz
# 	short : parentfolder.tar.gz
export BM_NAME_FORMAT="long"

# Type of archives:
#    - .tar
#    - .tar.gz
#    - .tar.bz2
export BM_FILETYPE="tar.gz"

# The backup method to use.
# Only one is supported in this release : "tarball"
export BM_BACKUP_METHOD="tarball"

# Number of days we have to keep an archive
export BM_MAX_TIME_TO_LIVE="5"

# Do you want to dereference the files pointed by symlinks ? 
# enter yes or no (yes can leed to huge archives, be careful).
export BM_DUMP_SYMLINKS="no"

# Do you want to replace duplicates by symlinks? 
# (archive-DAY is a duplicates of archive-(DAY - 1) if they 
# are both the same size).
export BM_PURGE_DUPLICATES="yes"

# Prefix of every archive on that box (default is HOSTNAME)
export BM_ARCHIVES_PREFIX="$HOSTNAME"

# Files you want to backup
export BM_DIRECTORIES="/etc /home"

# Files to exclude when generating tarballs
export BM_DIRECTORIES_BLACKLIST=""

##############################################################
# Repository
#############################################################

# Where to sotre the archives
export BM_ARCHIVES_REPOSITORY="/var/archives"

# For security reasons, the archive repository and the generated 
# archives will be readable/writable by a given user/group.
# You can choose to disable this if you like.
export BM_REPOSITORY_SECURE="yes"

# The repository will be readable/writable only by a specific 
# user:group pair if BM_REPOSITORY_SECURE is set to yes.
export BM_USER="root"
export BM_GROUP="root"

##############################################################
# Upload 
#############################################################

# you can set here a list of remote hosts where BM will upload
# the generated archives.

# which protocol to use for tranfert ? (scp or ftp)
export BM_UPLOAD_MODE=""

#"192.168.15.23 backup.company.com myhome.provider.net"
export BM_UPLOAD_HOSTS=""

# User for opening the remote connection
export BM_UPLOAD_USER=""

# Password, only needed for ftp transfert, scp is based on key identification.
export BM_UPLOAD_PASSWD=""

# cleans specified ftp folder before uploading (yes or no)
export BM_FTP_PURGE=""

# if scp mode is used, an identity file is needed
export BM_UPLOAD_KEY=""

#"/backup/upload/"
export BM_UPLOAD_DIR=""


##############################################################
# Automatic CDR/CDRW burning
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

