#
# Every method to manage backup are here.
# We should give here as more details we can
# on the specific conffiles to use for the methods.
#

# This should be called whenever an archive is made, it will dump some
# informations (size, md5sum) and will add the archive in .md5 file.
commit_archive()
{
	file_to_create="$1"
	size=$(size_of_path $file_to_create)
	info -n "\$file_to_create: ok (\${size}M, "
		
	base=$(basename $file_to_create)
	md5hash=$(get_md5sum $file_to_create)
	info "${md5hash})"
	echo "$md5hash $base" >> $BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${TODAY}.md5
		
	# Now that the file is created, remove previous duplicates if exists...
	purge_duplicate_archives $file_to_create || error "unable to purge duplicates"

	# security fixes if BM_REPOSITORY_SECURE is set to yes.
	if [ $BM_REPOSITORY_SECURE = yes ]; then
		chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $file_to_create
		chmod 660 $file_to_create
	fi
}

handle_tarball_error()
{
	target="$1"
	logfile="$2"

	warning "Unable to create \$target, check \$logfile"
	nb_err=$(($nb_err + 1))
}

backup_method_tarball()
{
	# Create the directories blacklist
	blacklist=""
	for pattern in $BM_TARBALL_BLACKLIST
	do
		blacklist="$blacklist --exclude=$pattern"
	done
	
	# Set the -h flag according to the $BM_TARBALL_DUMPSYMLINKS conf key
	# or the -y flag for zip. 
	h=""
	y="-y"
	if [ "$BM_TARBALL_DUMPSYMLINKS" = "yes" ] ||
	   [ "$BM_TARBALL_DUMPSYMLINKS" = "true" ]; then
		h="-h "
		y=""
	fi

	nb_err=0
	for DIR in $BM_TARBALL_DIRECTORIES
	do
		# first be sure the target exists
		if [ ! -e $DIR ] || [ ! -r $DIR ]; then
			warning "Target $DIR does not exist, skipping."
			nb_err=$(($nb_err + 1))
			continue
		fi
		
		dir_name=$(get_dir_name $DIR $BM_TARBALL_NAMEFORMAT)
		file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$TODAY.$BM_TARBALL_FILETYPE"
		
		if [ ! -f $file_to_create ] || [ $force = true ]; then
		   	
			case $BM_TARBALL_FILETYPE in
				tar.gz) # generate a tar.gz file if needed 
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $blacklist $h -c -z -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else
						rm -f $tarball_logfile
					fi
				;;
				tar.bz2|tar.bz) # generate a tar.bz2 file if needed
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $blacklist $h -c -j -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else
						rm -f $tarball_logfile
					fi
				;;
				tar) # generate a tar file if needed
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $blacklist $h -c -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else 
						rm -f $tarball_logfile
					fi
				;;
				zip) # generate a zip file if needed
					tarball_logfile=$(mktemp /tmp/bm-zip.log.XXXXXX)
					if ! ZIP="" ZIPOPT="" $zip $y -r "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else
						rm -f $tarball_logfile
					fi
				;;
				*) # unknown option
					error "The filetype \$BM_TARBALL_FILETYPE is not spported."
					_exit
				;;
			esac
		else
			warning "File \$file_to_create already exists, skipping."
			continue
		fi
			
		commit_archive "$file_to_create"
	done

	if [ $nb_err -gt 0 ]; then
		error "During the tarballs generation, \$nb_err error(s) occured."
	else
		rm -f $tarball_logfile
	fi
}

# 
# EXPERIMENTAL
# this is a feature in develpment, for developers only.
#
backup_method_rsync()
{
  # Not fully implemented, rsync is running in dry mode

  # Set the rsync options according to the $BM_TARBALL_DUMPSYMLINKS conf key
  rsync_options="-va"
  if [ ! -z $BM_TARBALL_DUMPSYMLINKS ]; then
    if [ "$BM_TARBALL_DUMPSYMLINKS" = "yes" ] ||
       [ "$BM_TARBALL_DUMPSYMLINKS" = "true" ]; then
      rsync_options="-vaL" 
    fi
  fi  
  
  for DIR in $BM_TARBALL_DIRECTORIES
  do
    if [ -n "$BM_UPLOAD_HOSTS" ]
    then
      if [ ! -z "$BM_UPLOAD_KEY" ]; then
        servers=`echo $BM_UPLOAD_HOSTS| sed 's/ /,/g'`
        for SERVER in $servers
        do
          ${rsync} ${rsync_options} -e "ssh -i ${BM_UPLOAD_KEY}" ${DIR} ${BM_UPLOAD_USER}@${SERVER}:${BM_UPLOAD_DIR}/${TODAY}/
        done
      else
        info "Need a key to use rsync"
      fi
    fi
  done
}

backup_method_mysql()
{
	if [ ! -x $mysqldump ]; then
		error "The \"mysql\" method is choosen, but \$mysqldump is not found."
	fi
	
	for database in $BM_MYSQL_DATABASES
	do
		file_to_create="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${database}.$TODAY.sql"
		if ! $mysqldump -u"$BM_MYSQL_ADMINLOGIN" -p"$BM_MYSQL_ADMINPASS" -h"$BM_MYSQL_HOST" -P$BM_MYSQL_PORT "$database" > "$file_to_create" ; then
			warning "Unable to dump the content of the database \$database"
		fi
	
		if [ ! -e "$file_to_create" ]; then
			warning "The file \$file_to_create was not created, skipping."
			continue
		fi
	
		case $BM_MYSQL_FILETYPE in
		gzip|gz)
			if ! $gzip -f -q -9 "$file_to_create" ; then
				warning "Unable to gzip \$file_to_create"
				continue
			fi
			if [ -f "${file_to_create}.gz" ]; then
				file_to_create="${file_to_create}.gz"
			else
				warning "Strangely, gzip succeeded but $file_to_create.gz does not exist."
				continue
			fi
		;;
		bzip2|bzip|bz2)
			if ! $bzip -f -q -9 "$file_to_create" ; then
				warning "Unable to bzip2 \$file_to_create"
				continue
			fi
			if [ -f "${file_to_create}.bz2" ]; then
				file_to_create="${file_to_create}.bz2"
			else
				warning "Strangely, bzip2 succeeded but $file_to_create.bz2 does not exist."
				continue
			fi
		;;
		uncompressed)
		;;
		*)
			error "This compression format is not supported: \$BM_MYSQL_FILETYPE"
		;;
		esac

		commit_archive "$file_to_create"
	done
}

__exec_meta_command()
{
        command="$1"
        file_to_create="$2"
        compress="$3"
        logfile=$(mktemp /tmp/bm-$archive.stderr.XXXXXX)
        
        # execute the command, grab the output
        $($command 1> $file_to_create 2>$logfile) || 
        error "Unable to exec \$command for \$archive; check \$logfile."

        # our $file_to_create should be created now
        if [ ! -e $file_to_create ]; then
               error "\$command ended, but \$file_to_create not found; check \$logfile" 
        fi
        rm -f $logfile
       
        if [ -n $compress ]; then
                case "$compress" in
                "gzip"|"gz")
                        if [ -x $gzip ]; then
                                $gzip -f $file_to_create || error "Error while using \$gzip."
                                file_to_create="$file_to_create.gz"
                        else
                                error "Compressor \$compress require \$gzip"
                        fi
                ;;
                "bzip"|"bzip2")
                        if [ -x $bzip ]; then
                                $bzip -f $file_to_create || error "Error while using \$bzip."
                                file_to_create="$file_to_create.bz2"
                        else
                                error "Compressor \$compress require \$bzip"
                        fi

                ;;
                "")
                ;;
                *)
                        error "No such compressor supported: \$compress"
                ;;
                esac
        fi
       
        # make sure we didn't loose the archive
        if [ ! -e $file_to_create ]; then
                error "Unable to find \$file_to_create" 
        fi
        
        export BM_RET="$file_to_create"
}

backup_method_pipe()
{
        index=0

        # parse each BM_PIPE_NAME's
        for archive in ${BM_PIPE_NAME[*]}
        do
                # make sure everything is here for this archive
                if [ -z "${BM_PIPE_COMMAND[$index]}" ] || 
                   [ -z "${BM_PIPE_FILETYPE[$index]}" ]; then
                        warning "Not enough args for this archive (\$archive), skipping."
                        continue
                fi
                command="${BM_PIPE_COMMAND[$index]}"
                filetype="${BM_PIPE_FILETYPE[$index]}"
                file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX-$archive.$TODAY.$filetype"
                compress="${BM_PIPE_COMPRESS[$index]}"
                
                # the magic stuff! 
                __exec_meta_command "$command" "$file_to_create" "$compress"
                file_to_create="$BM_RET"
                
                # commit the archive
                commit_archive "$file_to_create"

                # update the index mark 
                index=$(($index + 1))
        done
}

