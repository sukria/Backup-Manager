#!/bin/sh

##############################################################
# Archive settings
#############################################################

# the archive filename format
# 	long  : host-full-path-to-folder.tar.gz
# 	short : parentfolder.tar.gz
export BM_NAME_FORMAT="long"

# the type of archive to make (zip or tar.gz)
export BM_FILETYPE="tar.gz"

# the number of days we have to keep an archive
export BM_MAX_TIME_TO_LIVE="5"

# do you want to dereference the files pointed by symlinks ? 
# enter yes or no.
export BM_DUMP_SYMLINKS="no"

# the prefix of every archive on that box (default is HOSTNAME)
export BM_ARCHIVES_PREFIX="$HOSTNAME"


##############################################################
# File paths
#############################################################

# the root directory where all the archives should live (default is /backup/)
export BM_ARCHIVES_REPOSITORY="/backup"

# the directories you want to backup
export BM_DIRECTORIES="/etc /home"

# Here the list of the directories you don't want to archive
export BM_DIRECTORIES_BLACKLIST=""


##############################################################
# upload settings
#############################################################

# you can set here a list of remote hosts where BM will upload
# the generated archives.

# which protocol to use for tranfert ? (scp or ftp)
export BM_UPLOAD_MODE=""

#"192.168.15.23 backup.company.com myhome.provider.net"
export BM_UPLOAD_HOSTS=""

#"bman"
export BM_UPLOAD_USER=""

#"secret", only needed for ftp transfert, scp is based on key identification.
export BM_UPLOAD_PASSWD=""

# if scp mode is used, an identity file is needed
export BM_UPLOAD_KEY=""

#"/backup/upload/"
export BM_UPLOAD_DIR=""


##############################################################
# Automatic CD/DVD burning settings 
#############################################################

# set this to yes if you want automatic burning.
export BM_BURNING="yes"

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

