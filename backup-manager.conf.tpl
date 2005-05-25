##############################################################
# Archives
#############################################################

# Archive filename format
# 	long  : host-full-path-to-folder.tar.gz
# 	short : parentfolder.tar.gz
export BM_NAME_FORMAT="long"

# Type of archive to make (zip or tar.gz)
export BM_FILETYPE="tar.gz"

# Number of days we have to keep an archive
export BM_MAX_TIME_TO_LIVE="5"

# Do you want to dereference the files pointed by symlinks ? 
# enter yes or no (yes can leed to huge archives, be careful).
export BM_DUMP_SYMLINKS="no"

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

# The repository will be readable/writable only by a specific 
# user:group pair for security reasons.
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

# which media to use (cdrom or dvd)
# cd will use cdrecord, dvd will use growisofs
# only cdrom is supported currently !
export BM_BURNING_MEDIA="cdrom"

# The device to use for cdrecord.
export BM_BURNING_DEVICE="/dev/cdrom"

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

# Enter here some shell script.
# It will be executed before the first action of backup-manager.
export BM_PRE_BACKUP_COMMAND=""

# Enter here some shell script.
# It will be executed after the last action of backup-manager.
export BM_POST_BACKUP_COMMAND=""

