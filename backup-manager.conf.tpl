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

# Where to place temporary files
export BM_TEMP_DIR="/tmp"

# For security reasons, the archive repository and the generated 
# archives will be readable/writable by a given user/group.
# This is recommended to set this to true.
export BM_REPOSITORY_SECURE="true"

# The repository will be readable/writable only by a specific 
# user:group pair if BM_REPOSITORY_SECURE is set to true.
export BM_REPOSITORY_USER="root"
export BM_REPOSITORY_GROUP="root"
# You can also choose the permission to set the repository, default 
# is 770, pay attention to what you do there!
export BM_REPOSITORY_CHMOD="770"

##############################################################
# Archives - let's focus on the precious tarballs...
##############################################################

# Each archive generated will be chmoded for security reasons
# (BM_REPOSITORY_SECURE should be enabled for this).
export BM_ARCHIVE_CHMOD="660"

# Number of days we have to keep an archive (Time To Live)
export BM_ARCHIVE_TTL="5"

# At which frequency will you build your archives?
# You can choose either "daily" or "hourly". 
# This should match your CRON configuration.
export BM_ARCHIVE_FREQUENCY="daily"

# Do you want to purge only the top-level directory or all
# directories under BM_REPOSITORY_ROOT?
export BM_REPOSITORY_RECURSIVEPURGE="false"

# Do you want to replace duplicates by symlinks? 
# (archive-DAY is a duplicate of archive-(DAY - 1) if they 
# are both the same according to MD5 hashes).
export BM_ARCHIVE_PURGEDUPS="true"

# Prefix of every archive on that box (default is HOSTNAME)
export BM_ARCHIVE_PREFIX="$HOSTNAME"

# Should we purge only archives built with $BM_ARCHIVE_PREFIX
export BM_ARCHIVE_STRICTPURGE="true"

# You may want to nice the commands run for archive-creation
# (Recommanded for desktop users.)
# Choose a nice level from -20 (most favorable scheduling) to 19 (least favorable).
export BM_ARCHIVE_NICE_LEVEL="10"

# The backup method to use.
# Available methods are:
# - tarball
# - tarball-incremental
# - mysql
# - mariadb
# - pgsql
# - mongodb
# - svn
# - pipe
# - none
# If you don't want to use any backup method (you don't want to
# build archives) then choose "none"
export BM_ARCHIVE_METHOD="tarball"

##############################################################
# Encryption - because you cannot trust the place your 
#              archives are
##############################################################

# If you want to encrypt your archives locally, Backup Manager 
# can use GPG while building the archive (so the archive is never
# written to the disk without being encrypted.

# Note: this feature is only possible with the following archive types:
# tar, tar.gz, tar.bz2

# Uncomment the following line if you want to enable encryption
# export BM_ENCRYPTION_METHOD="gpg"

# The encryption will be made using a GPG ID
# Examples:
# export BM_ENCRYPTION_RECIPIENT="0x1EE5DD34"
# export BM_ENCRYPTION_RECIPIENT="Alexis Sukrieh"
# export BM_ENCRYPTION_RECIPIENT="sukria@sukria.net"


##############################################################
# Section "TARBALL"
# - Backup method: tarball
#############################################################

# Archive filename format
# 	long  : host-full-path-to-folder.tar.gz
# 	short : parentfolder.tar.gz
export BM_TARBALL_NAMEFORMAT="long"

# Type of archives
# Available types are:
#     tar, tar.gz, tar.bz2, tar.xz, tar.lzma, tar.zst, dar, zip.
# Make sure to satisfy the appropriate dependencies 
# (bzip2, dar, xz, lzma, zstd...).
export BM_TARBALL_FILETYPE="tar.gz"

# You can choose to build archives remotely over SSH.
# You will then need to fill the BM_UPLOAD_SSH variables 
# (BM_UPLOAD_SSH_HOSTS, BM_UPLOAD_SSH_USER, BM_UPLOAD_SSH_KEY).
# If this boolean is set to true, archive will be saved locally (in 
# BM_REPOSITORY_ROOT but will be built by the remote host).
# Thus, BM_TARBALL_DIRECTORIES will be used to backup remote directories.
# Those archive will be prefixed with the remote host name.
export BM_TARBALL_OVER_SSH="false"

# Do you want to dereference the files pointed by symlinks ? 
# enter true or false (true can lead to huge archives, be careful).
export BM_TARBALL_DUMPSYMLINKS="false"

# Targets to backup

# You can use two different variables for defining the targets of 
# your backups, either a simple space-separated list (BM_TARBALL_DIRECTORIES)
# or an array (BM_TARBALL_TARGETS[]).
# Use the first one for simple path that doesn't contain spaces in their name.
# Use the former if you want to specify paths to backups with spaces.

# It's recommanded to use BM_TARBALL_TARGETS[] though.
# Warning! You *must not* use both variables at the same time.

# Paths without spaces in their name:
# export BM_TARBALL_DIRECTORIES="/etc /boot"

# If one or more of the targets contain a space, use the array:
declare -a BM_TARBALL_TARGETS

BM_TARBALL_TARGETS[0]="/etc" 
BM_TARBALL_TARGETS[1]="/boot"

export BM_TARBALL_TARGETS

# Files to exclude when generating tarballs, you can put absolute 
# or relative paths, Bash wildcards are possible.
export BM_TARBALL_BLACKLIST="/dev /sys /proc /tmp"

# With the "dar" filetype, you can choose a maximum slice limit.
export BM_TARBALL_SLICESIZE="1000M"

# Extra options to append to the tarball generation 
# (take care to what you do; this will be silently added to the 
# command line.)
export BM_TARBALL_EXTRA_OPTIONS=""

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

# Examples: you want to make master tarballs every friday:
# BM_TARBALLINC_MASTERDATETYPE="weekly"
# BM_TARBALLINC_MASTERDATEVALUE="5"
#
# Or every first day of the month:
# BM_TARBALLINC_MASTERDATETYPE="monthly"
# BM_TARBALLINC_MASTERDATEVALUE="1"

##############################################################
# Backup method: MYSQL / MARIADB
#############################################################

# This method is dedicated to MySQL and MariaDB databases.
# You should not use the tarball method for backing up database
# directories or you may have corrupted archives.
# Enter here the list of databases to backup.
# Wildcard: __ALL__ (will dump all the databases in one archive)
export BM_MYSQL_DATABASES="__ALL__"

# The best way to produce MySQL dump is done by using the "--opt" switch 
# of mysqldump. This make the dump directly usable with mysql (add the drop table
# statements), lock the tables during the dump and other things.
# This is recommended for full-clean-safe backups, but needs a 
# privileged user (for the lock permissions).
export BM_MYSQL_SAFEDUMPS="true"

# The user who is allowed to read every databases filled in BM_MYSQL_DATABASES
export BM_MYSQL_ADMINLOGIN="root"

# its password
export BM_MYSQL_ADMINPASS=""

# the host where the database is
export BM_MYSQL_HOST="localhost"

# the port where MySQL listen to on the host. Leave empty if you're using unix_socket auth.
export BM_MYSQL_PORT="3306"

# which compression format to use? (gzip, bzip2 or zstd)
export BM_MYSQL_FILETYPE="bzip2"

# Extra options to append to mysqldump
# (take care to what you do; this will be silently added to the 
# command line.)
export BM_MYSQL_EXTRA_OPTIONS=""

# Make separate backups of each database?
export BM_MYSQL_SEPARATELY="true"

# Specify DBs to exclude here (separated by space) 
export BM_MYSQL_DBEXCLUDE=""

##############################################################
# Backup method: PostgreSQL
#############################################################

# This method is dedicated to PostgreSQL databases.
# You should not use the tarball method for backing up database
# directories or you may have corrupted archives.
# Enter here the list of databases to backup.
# Wildcard: __ALL__ (will dump all the databases in one archive)
export BM_PGSQL_DATABASES="__ALL__"

# The user who is allowed to read every databases filled in BM_PGSQL_DATABASES
export BM_PGSQL_ADMINLOGIN="root"

# its password
export BM_PGSQL_ADMINPASS=""

# the host where the database is
export BM_PGSQL_HOST="localhost"

# the port where PostgreSQL listen to on the host
export BM_PGSQL_PORT="5432"

# which compression format to use? (gzip, bzip2 or zstd)
export BM_PGSQL_FILETYPE="bzip2"

# Extra options to append to pg_dump
# (take care to what you do; this will be silently added to the 
# command line.)
export BM_PGSQL_EXTRA_OPTIONS=""

##############################################################
# Backup method: mongodb
#############################################################

# This method is dedicated to MongoDB databases.
# Enter here the list of databases to backup.
# Wildcard: __ALL__ (will dump all the databases in one archive)
export BM_MONGODB_DATABASES="__ALL__"

# The user who is allowed to read every databases filled in BM_MYSQL_DATABASES
# Typical sysbackup user can be created by the following command:
# mongo --quiet --username=root admin
# > use admin
# > db.createUser({user:"sysbackup",pwd:"somesecret",roles:["backup","clusterAdmin","readAnyDatabase"]});
# > quit()
export BM_MONGODB_BACKUPLOGIN="sysbackup"

# its password
export BM_MONGODB_BACKUPPASS=""

# the host where the database is
export BM_MONGODB_HOST="localhost"

# the port where MySQL listen to on the host
export BM_MONGODB_PORT="27017"

# Extra options to append to mysqldump
# (take care to what you do; this will be silently added to the 
# command line.)
export BM_MONGODB_EXTRA_OPTIONS=""

# Make separate backups of each database?
export BM_MONGODB_SEPARATELY="true"

# Specify DBs to exclude here (separated by space) 
export BM_MONGODB_DBEXCLUDE=""

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
# - ssh-gpg
# - ftp
# - rsync
# - s3
# - none

# If you don't want to use any upload method (you don't want to
# upload files to remote hosts) then choose "none"
export BM_UPLOAD_METHOD=""

# where to upload (global to all methods. Not required to be set for S3)
export BM_UPLOAD_HOSTS=""

# Where to put archives on the remote hosts (global)
export BM_UPLOAD_DESTINATION=""

# Uncomment the 'export ...' line below to activate the uploaded archives
# database.
# Using the database will avoid extraneous uploads to remote hosts in the
# case of running more than one backup-manager jobs per day (such as when
# you are using different configuration files for different parts of your
# filesystem).
# Note that when you upload to multiple hosts, a single succesfull upload
# will mark the archive as uploaded. Thus upload errors to specific hosts
# will have to be resolved manually.
# You can specify any filename, but it is recommended to keep the database
# inside the archive repository. The variable's value has been preset to
# that.
#export BM_UPLOADED_ARCHIVES=${BM_REPOSITORY_ROOT}/${BM_ARCHIVE_PREFIX}-uploaded.list

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

# purge archives on remote hosts before uploading?
export BM_UPLOAD_SSH_PURGE="true"

# If you set BM_UPLOAD_SSH_PURGE, you can specify a time to live 
# for archives uploaded with SSH.
# This can let you use different ttl's locally and remotely
# By default, BM_ARCHIVE_TTL will be used.
export BM_UPLOAD_SSH_TTL=""

##############################################################
# The SSH-GPG method
# The ssh-gpg method uses the same configuration keys as the 
# ssh method, plus one other
#############################################################

# The gpg public key used for encryption, this can be a short 
# or long key id, or a descriptive name. See gpg man page for 
# all possibilities how to specify a key.
export BM_UPLOAD_SSHGPG_RECIPIENT=""

##############################################################
# The FTP method
#############################################################

# Use FTP secured transfers (FTP over TLS)
# User, password and data will be uploaded encrypted with SSL.
# Passive mode will be automaticaly activated
export BM_UPLOAD_FTP_SECURE="false"

# Do you want to use FTP passive mode?
# This is mandatory for NATed/firewalled environments 
export BM_UPLOAD_FTP_PASSIVE="true"

# Timeout (in seconds) for FTP transfer
# This setting only has effect when using FTP transfer with
# secure mode disabled (BM_UPLOAD_FTP_SECURE to "false")
export BM_UPLOAD_FTP_TIMEOUT="120"

# Test the FTP connection before starting archives upload.
# This will enable BM to try sending a 2MB test file before
# sending any archive
export BM_UPLOAD_FTP_TEST="false"

# the user to use for the FTP connections/transfers
export BM_UPLOAD_FTP_USER=""

# the FTP user's password
export BM_UPLOAD_FTP_PASSWORD=""

# FTP specific remote hosts
export BM_UPLOAD_FTP_HOSTS=""

# purge archives on remote hosts before uploading?
export BM_UPLOAD_FTP_PURGE="true"

# You can specify a time to live for archives uploaded with FTP
# This can let you use different ttl's locally and remotely
# By default, BM_ARCHIVE_TTL will be used.
export BM_UPLOAD_FTP_TTL=""

# destination for FTP uploads (overrides BM_UPLOAD_DESTINATION)
export BM_UPLOAD_FTP_DESTINATION=""


##############################################################
# The S3 method
#############################################################

# The Amazon S3 method requires that you secure an S3
# account. See http://aws.amazon.com

# The bucket to upload to. This bucket must be dedicated to backup-manager
export BM_UPLOAD_S3_DESTINATION=""

# the S3 access key provided to you
export BM_UPLOAD_S3_ACCESS_KEY=""

# the S3 secret key provided to you
export BM_UPLOAD_S3_SECRET_KEY=""

# purge archives on remote hosts before uploading?
export BM_UPLOAD_S3_PURGE="false"

# You can specify a time to live for archives uploaded to S3
# This can let you use different ttl's locally and remotely
# By default, BM_ARCHIVE_TTL will be used.
export BM_UPLOAD_S3_TTL=""

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

# Files/folders to exclude when rsyncing. Warning: rsync will interpret
# it as a mask, so will exclude any file/folder corresponding to it
export BM_UPLOAD_RSYNC_BLACKLIST=""

# Extra options to append to rsync
# (take care to what you do; this will be silently added to the
# command line.)
export BM_UPLOAD_RSYNC_EXTRA_OPTIONS=""

# Do you want to limit the maximum available bandwidth rsync
# can use ?
# By default, no bandwidth limit is applied.
# Example: 32M, 1024K, ...
export BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT=""

##############################################################
# Section "BURNING" 
# - Automatic CDR/CDRW/DVDR burning
#############################################################

# the method of burning archives from the list :
#  - DVD    : burn archives on a DVD medium
#             (that doesn't need formatting, like DVD+RW).
#
#  - DVD-RW : blank the DVD medium and burn archives 
#             (recommanded for DVD-RW media).
#
#  - CDRW   : blank the CDRW and burn the whole 
#             ARCHIVES_REPOSITORY or only 
#             the generated archives.
#
#  - CDR    : burn the whole ARCHIVES_REPOSITORY or 
#             only the generated archives.
#  - none   : disable the burning system
#
# Note that if backup-manager is run from interactive prompt you
# will be asked to insert disc(s) when needed

export BM_BURNING_METHOD="none"

# When the CD is burnt, it is possible to check every file's 
# MD5 checksum to see if the CD is not corrupted.
export BM_BURNING_CHKMD5="false"

# The device to use for mounting the cdrom
export BM_BURNING_DEVICE="/dev/cdrom"

# You can force cdrecord to use a specific device
# Fill in the full path to the device to use or even
# e.g. BM_BURNING_DEVFORCED="/dev/cdrom"
# If none specified, the default cdrecord device will be used.
export BM_BURNING_DEVFORCED=""

# By default backup-manager will make Joliet media (using the mkisofs switches
# : "-R -J"). You can change these if you want to use non-Joliet disc images.
# Change this only if you know what you're doing. Refer to mkisofs(8) for
# details.
export BM_BURNING_ISO_FLAGS="-R -J"

# enter here the max size of your media 
# (usal sizes are 4200 for DVD media and 700 or 800 for CDR media)
export BM_BURNING_MAXSIZE="650"


##############################################################
# Advanced settings, use this with care.
#############################################################

# Every output made can be sent to syslog
# set this to "true" or "false"
export BM_LOGGER="true"

# Which level of messages do you want to log to syslog?
# possible values are : debug,info,warning,error
export BM_LOGGER_LEVEL="warning"

# You can choose which facility to use
export BM_LOGGER_FACILITY="user"

# Enter here some shell script.
# It will be executed before the first action of backup-manager.
export BM_PRE_BACKUP_COMMAND=""

# Enter here some shell script.
# It will be executed after the last action of backup-manager.
export BM_POST_BACKUP_COMMAND=""

