#  Backup Manager Configuration File
#
#  * This configuration file is divided into sections.
#    The 'global' section is mandatory, every keys defined in 
#    this section are inherited in the other sections.
#  * There is one section per "backup method", you have to 
#    fill the section of the chosen method.
#
##############################################################

##############################################################
# Repository - everything about where archives are
#############################################################
# Where to store the archives
export BM_REPOSITORY_ROOT="/var/archives"
# For security reasons, the archive repository and the generated 
# archives will be readable/writable by a given user/group.
# This is recommended to set this to true.
export BM_REPOSITORY_SECURE="true"
# The repository will be readable/writable only by a specific 
# user:group pair if BM_REPOSITORY_SECURE is set to true.
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
export BM_ARCHIVE_PURGEDUPS="true"
# Prefix of every archive on that box (default is HOSTNAME)
export BM_ARCHIVE_PREFIX="$HOSTNAME"

# The backup method to use.
# Available methods are:
# - tarball
# - tarball-incremental
# - mysql
# - svn
# - pipe
# - none
# If you don't want to use any backup method (you don't want to
# build archives) then choose "none"
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
# enter true or false (true can lead to huge archives, be careful).
export BM_TARBALL_DUMPSYMLINKS="false"
# Directories you want to backup as tarballs (separated by spaces)
export BM_TARBALL_DIRECTORIES="/etc /home"
# Files to exclude when generating tarballs
export BM_TARBALL_BLACKLIST=""

##############################################################
# The tarball-incremental method uses the same keys as the 
# tarball method, plus two others.
#############################################################
# Which frequency to use for the master tarball?
# possible values: weekly, monthly
export BM_TARBALLINC_MASTERDATETYPE="weekly"
# Number of the day, in the BM_TARBALLINC_MASTERDATETYPE frequency
# when master tarballs should be made
export BM_TARBALLINC_MASTERDATEVALUE="1"
# Examples: you want to make maser tarballs every friday:
# BM_TARBALLINC_MASTERDATETYPE="weekly"
# BM_TARBALLINC_MASTERDATEVALUE="5"
#
# Or every first day of the month:
# BM_TARBALLINC_MASTERDATETYPE="monthly"
# BM_TARBALLINC_MASTERDATEVALUE="1"

##############################################################
# Backup method: MYSQl
#############################################################
# This method is dedicated to MySQL databases.
# You should not use the tarball method for backing up database
# directories or you may have corrupted archives.
# Enter here the list of databases
export BM_MYSQL_DATABASES="mysql"
# The user who is allowed to read every databases filled in BM_MYSQL_DATABASES
export BM_MYSQL_ADMINLOGIN="root"
# its password
export BM_MYSQL_ADMINPASS=""
# the host where the database is
export BM_MYSQL_HOST="localhost"
# the port where MySQL listen to on the host
export BM_MYSQL_PORT="3306"
# which compression format to use? (gzip or bzip2)
export BM_MYSQL_FILETYPE="bzip2"

##############################################################
# Backup method: svn
#############################################################
# Absolute paths to the svn repositories to archive
export BM_SVN_REPOSITORIES=""
# You can compress the resulting XML files 
# Supported compressor are: bzip2 and gzip
export BM_SVN_COMPRESSWITH="bzip2"

##############################################################
# Backup method: pipe
#############################################################
# The "pipe" method is a generic way of making archive.
# Its concept is simple, for every kind of archive you want
# to make, you give: a command which will send output on stdout,
# a name, a file type and optionnaly, a compressor. 

# Be careful, this feature uses arrays!
declare -a BM_PIPE_COMMAND
declare -a BM_PIPE_NAME
declare -a BM_PIPE_FILETYPE
declare -a BM_PIPE_COMPRESS

# You can virtually implement whatever backup scenario you like 
# with this method.
#
# The resulting archives will be named like this: 
# $BM_ARCHIVE_PREFIX-$BM_PIPE_NAME.$DATE.$BM_PIPE_FILETYPE
# If you specified a BM_PIPE_COMPRESS option, the resulting filename 
# will change as expected (eg, .gz if "gzip").
#
# Here are a couple of examples for using this method:

# Archive a remote MySQL database through SSH:
#    BM_PIPE_COMMAND[0]="ssh host -c \"mysqldump -ufoo -pbar base\"" 
#    BM_PIPE_NAME[0]="base" 
#    BM_PIPE_FILETYPE[0]="sql"
#    BM_PIPE_COMPRESS[0]="gzip"
# This will make somthing like: localhost-base.20050421.sql.gz

# Archive a specific directory, on a remote server through SSH:
#    BM_PIPE_COMMAND[0]="ssh host -c \"tar -c -z /home/user\"" 
#    BM_PIPE_NAME[0]="host.home.user" 
#    BM_PIPE_FILETYPE[0]="tar.gz"
#    BM_PIPE_COMPRESS[0]=""
# This will make somthing like: localhost-host.home.user.20050421.tar.gz

export BM_PIPE_COMMAND
export BM_PIPE_NAME
export BM_PIPE_FILETYPE
export BM_PIPE_COMPRESS

##############################################################
# Section "UPLOAD"
# You can upload archives to remote hosts with different 
# methods.
#############################################################
# Which method to use for uploading archives, you can put 
# multiple methods here.
# Available methods:
# - scp
# - ftp
# - rsync
# - none
# If you don't want to use any upload method (you don't want to
# upload files to remote hosts) then choose "none"
export BM_UPLOAD_METHOD=""
# where to upload (global to all methods)
export BM_UPLOAD_HOSTS=""
# Where to put archives on the remote hosts (global)
export BM_UPLOAD_DESTINATION=""

##############################################################
# The SSH method
#############################################################
# the user to use for the SSH connections/transfers
export BM_UPLOAD_SSH_USER=""
# The private key to use for opening the connection
export BM_UPLOAD_SSH_KEY=""
# specific ssh hosts 
export BM_UPLOAD_SSH_HOSTS=""
# port to use for SSH connections (leave blank for default one)
export BM_UPLOAD_SSH_PORT=""
# destination for ssh uploads (overrides BM_UPLOAD_DESTINATION)
export BM_UPLOAD_SSH_DESTINATION=""

##############################################################
# The FTP method
#############################################################
# the user to use for the FTP connections/transfers
export BM_UPLOAD_FTP_USER=""
# the FTP user's password
export BM_UPLOAD_FTP_PASSWORD=""
# FTP specific rmeote hosts
export BM_UPLOAD_FTP_HOSTS=""
# purge archives on remote hosts before uploading?
export BM_UPLOAD_FTP_PURGE="false"
# destination for FTP uploads (overrides BM_UPLOAD_DESTINATION)
export BM_UPLOAD_FTP_DESTINATION=""


##############################################################
# The RSYNC method
#############################################################

# Which directories should be backuped with rsync
export BM_UPLOAD_RSYNC_DIRECTORIES=""

# Destination for rsync uploads (overrides BM_UPLOAD_DESTINATION) 
export BM_UPLOAD_RSYNC_DESTINATION=""

# The list of remote hosts, if you want to enable the upload
# system, just put some remote hosts here (fqdn or IPs)
# Leave it empty if you want to use the hosts that are defined in
# BM_UPLOAD_HOSTS
export BM_UPLOAD_RSYNC_HOSTS=""

# Do you want to dereference the files pointed by symlinks?   
# enter true or false (true can lead to huge archives, be careful).    
export BM_UPLOAD_RSYNC_DUMPSYMLINKS="false"

##############################################################
# Section "BURNING" 
# - Automatic CDR/CDRW/DVDR burning
#############################################################

# the method of burning archives from the list :
#  - DVD  : burn archives on a DVD media.
#
#  - CDRW : blank the CDRW and burn the whole 
#           ARCHIVES_REPOSITORY or only 
#           the generated archives.
#
#  - CDR  : burn the whole ARCHIVES_REPOSITORY or 
#           only the generated archives.
#  - none : disable the burning system

export BM_BURNING_METHOD="none"

# When the CD is burnt, it is possible to check every file's 
# MD5 checksum to see if the CD is not corrupted.
export BM_BURNING_CHKMD5="true"

# The device to use for mounting the cdrom
export BM_BURNING_DEVICE="/dev/cdrom"

# You can force cdrecord to use a specific device
# Fill in the full path to the device to use or even
# e.g. BM_BURNING_DEVFORCED="/dev/cdrom"
# If none specified, the default cdrecord device will be used.
export BM_BURNING_DEVFORCED=""
# enter here the max size of your media 
# (usal sizes are 4200 for DVD media and 700 or 800 for CDR media)
export BM_BURNING_MAXSIZE="700"


##############################################################
# Advanced settings, use this with care.
#############################################################

# Every output made can be sent to syslog
# set this to "true" or "false"
export BM_LOGGER="true"

# You can choose which facility to use
export BM_LOGGER_FACILITY="user"

# Enter here some shell script.
# It will be executed before the first action of backup-manager.
export BM_PRE_BACKUP_COMMAND=""

# Enter here some shell script.
# It will be executed after the last action of backup-manager.
export BM_POST_BACKUP_COMMAND=""

