#
# Every method to manage backup are here.
# We should give here hte more details we can
# on the specific conffiles to use for the methods.
#


backup_method_tarball()
{
	# Create the directories blacklist
	blacklist=""
	for pattern in $BM_DIRECTORIES_BLACKLIST
	do
		blacklist="$blacklist --exclude=$pattern"
	done
	
	# Set the -h flag according to the $BM_DUMP_SYMLINKS conf key
	# or the -y flag for zip. 
	h=""
	y="-y"
	if [ "$BM_DUMP_SYMLINKS" = "yes" ] ||
	   [ "$BM_DUMP_SYMLINKS" = "true" ]; then
		h="-h "
		y=""
	fi

	for DIR in $BM_DIRECTORIES
	do
		dir_name=$(get_dir_name $DIR $BM_NAME_FORMAT)
		file_to_create="$BM_ARCHIVES_REPOSITORY/$BM_ARCHIVES_PREFIX$dir_name.$TODAY.$BM_FILETYPE"
		
		if [ ! -f $file_to_create ] || [ $force = true ]; then
		   	
			info -n "Creating \$file_to_create: "
			
			case $BM_FILETYPE in
				tar.gz) # generate a tar.gz file if needed 
					$tar $blacklist $h -c -z -f "$file_to_create" "$DIR" > /dev/null 2>&1 || info -n '~'
				;;
				tar.bz2|tar.bz) # generate a tar.bz2 file if needed
					$tar $blacklist $h -c -j -f "$file_to_create" "$DIR" > /dev/null 2>&1 || info '~'
				;;
				tar) # generate a tar file if needed
					$tar $blacklist $h -c -f "$file_to_create" "$DIR" > /dev/null 2>&1 || info '~'
				;;
				zip) # generate a zip file if needed
					ZIP="" ZIPOPT="" $zip $y -r "$file_to_create" "$DIR" > /dev/null 2>&1 || info '~'
				;;
				*) # unknown option
					info "failed"
					error "The filetype \$BM_FILETYPE is not spported."
					_exit
				;;
			esac
		else
			warning "File \$file_to_create already exists, skipping."
			continue
		fi
			
		size=$(size_of_path $file_to_create)
		info -n "ok (\${size}M, "
		
		base=$(basename $file_to_create)
		md5hash=$(get_md5sum $file_to_create)
		info "${md5hash})"
		echo "$md5hash $base" >> $BM_ARCHIVES_REPOSITORY/${BM_ARCHIVES_PREFIX}-${TODAY}.md5
		
		# Now that the file is created, remove previous duplicates if exists...
		purge_duplicate_archives $file_to_create || error "unable to purge duplicates"

		# security fixes if BM_REPOSITORY_SECURE is set to yes.
		if [ $BM_REPOSITORY_SECURE = yes ]; then
			chown $BM_USER:$BM_GROUP $file_to_create
			chmod 660 $file_to_create
		fi
	done
}

# 
# EXPERIMENTAL
# this is a feature in develpment, for developers only.
#
backup_method_rsync()
{
  # Not fully implemented, rsync is running in dry mode

  # Set the rsync options according to the $BM_DUMP_SYMLINKS conf key
  rsync_options="-va"
  if [ ! -z $BM_DUMP_SYMLINKS ]; then
    if [ "$BM_DUMP_SYMLINKS" = "yes" ] ||
       [ "$BM_DUMP_SYMLINKS" = "true" ]; then
      rsync_options="-vaL" 
    fi
  fi  
  
  for DIR in $BM_DIRECTORIES
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
	error "backup_method_mysql is not yet supported"
}

backup_method_pipe()
{
	error "backup_method_pipe is not yet supported"
#		# first extract the shell command
#		bm_command=$(echo ${BM_BACKUP_METHOD/|/})
#		info "Using a pipe method for backup: $bm_command"
#		
#		# now run the command and redirect the output in our $file_to_create
#		$($bm_command > $file_to_create) || error "Unable to run the custom backup command: \$bm_command"
#
#		# now we have data in $file_to_create, maybe we have to compress the file
#		# we look at BM_BACKUP_COMPRESS for that	
}

