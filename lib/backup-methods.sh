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
	str=$(echo_translated "\$file_to_create: ok (\${size}M,")
		
	base=$(basename $file_to_create)
	md5hash=$(get_md5sum $file_to_create)
	info "$str ${md5hash})"
	echo "$md5hash  $base" >> $BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${TODAY}.md5
		
	# Now that the file is created, remove previous duplicates if exists...
	purge_duplicate_archives $file_to_create || error "Unable to purge duplicates of \$file_to_create"

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

__exec_meta_command()
{
        command="$1"
        file_to_create="$2"
        compress="$3"
        logfile=$(mktemp /tmp/bm-command.stderr.XXXXXX)
        
	if [ -f $file_to_create ] && [ $force != true ]; then
                warning "File \$file_to_create already exists, skipping."
        fi
        
        # execute the command, grab the output
        $($command 1> $file_to_create 2>$logfile) || 
        error "Unable to exec \$command; check \$logfile"

        # our $file_to_create should be created now
        if [ ! -e $file_to_create ]; then
               error "\$command ended, but \$file_to_create not found; check \$logfile" 
        fi
        rm -f $logfile
       
        if [ -n $compress ]; then
                case "$compress" in
                "gzip"|"gz")
                        if [ -x $gzip ]; then
                                $gzip -f -q -9 $file_to_create || error "Error while using \$gzip."
                                file_to_create="$file_to_create.gz"
                        else
                                error "Compressor \$compress require \$gzip"
                        fi
                ;;
                "bzip"|"bzip2")
                        if [ -x $bzip ]; then
                                $bzip -f -q -9 $file_to_create || error "Error while using \$bzip."
                                file_to_create="$file_to_create.bz2"
                        else
                                error "Compressor \$compress require \$bzip"
                        fi

                ;;
                ""|"uncompressed"|"none")
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

# This manages both "tarball" and "tarball-incremental" methods.
# configuration keys: BM_TARBALL_* and BM_TARBALLINC_*
backup_method_tarball()
{
	info "Using method \"\$BM_ARCHIVE_METHOD\""
	
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

                # needed for the incremental method
                incremental_list="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.incremental-list.txt"
		
                # handling of incremental options
                if [ "$BM_ARCHIVE_METHOD" = "tarball-incremental" ]; then
        
                        incremental=""
                        is_master_day="false"

                        case $BM_TARBALLINC_MASTERDATETYPE in
                        weekly)
                                master_day=$(date +'%w')
                        ;;
                        monthly)
                                master_day=$(date +'%d')
                        ;;
                        *)
                                error "Unknown frequency: \$BM_TARBALLINC_MASTERDATETYPE"
                        ;;
                        esac
                        
                        if [ -z "$BM_TARBALLINC_MASTERDATEVALUE" ]; then
                                BM_TARBALLINC_MASTERDATEVALUE="1"
                        fi
                        if [ $master_day = $BM_TARBALLINC_MASTERDATEVALUE ]; then
                                is_master_day="true"
                        fi

                        # if master day, we have to purge the incremental list if exists
                        # so we'll generate a new one (and then, a full backup).
                        if [ "$is_master_day" = "true" ] && 
                           [ -e $incremental_list ]; then
                                rm -f $incremental_list
                        fi
                        incremental="--listed-incremental $incremental_list"
                fi

		if [ ! -f $file_to_create ] || [ $force = true ]; then
		   	
			case $BM_TARBALL_FILETYPE in
				tar.gz) # generate a tar.gz file if needed 
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $incremental $blacklist $h -p -c -z -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else
						rm -f $tarball_logfile
					fi
				;;
				tar.bz2|tar.bz) # generate a tar.bz2 file if needed
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $incremental $blacklist $h -p -c -j -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
						handle_tarball_error "$file_to_create" "$tarball_logfile"
					else
						rm -f $tarball_logfile
					fi
				;;
				tar) # generate a tar file if needed
					tarball_logfile=$(mktemp /tmp/bm-tar.log.XXXXXX)
					if ! $tar $incremental $blacklist $h -p -c -f "$file_to_create" "$DIR" > $tarball_logfile 2>&1 ; then
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

backup_method_mysql()
{
	info "Using method \"\$BM_ARCHIVE_METHOD\""
	if [ ! -x $mysqldump ]; then
		error "The \"mysql\" method is choosen, but \$mysqldump is not found."
	fi
	
	for database in $BM_MYSQL_DATABASES
	do
		file_to_create="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${database}.$TODAY.sql"
		command="$mysqldump -u$BM_MYSQL_ADMINLOGIN -p$BM_MYSQL_ADMINPASS -h$BM_MYSQL_HOST -P$BM_MYSQL_PORT $database"
                compress="$BM_MYSQL_FILETYPE"	
         
                __exec_meta_command "$command" "$file_to_create" "$compress"
                file_to_create="$BM_RET"

		commit_archive "$file_to_create"
	done
}

backup_method_svn()
{
	info "Using method \"\$BM_ARCHIVE_METHOD\""
        if [ ! -x $svnadmin ]; then
                error "The \"svn\" method is choosen, but \$svnadmin is not found."
        fi

        for repository in $BM_SVN_REPOSITORIES
        do
                archive_name=$(get_dir_name $repository "long")
                file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$archive_name.$TODAY.svn"
                command="$svnadmin dump $repository"
                compress="$BM_SVN_COMPRESSWITH"
                
                __exec_meta_command "$command" "$file_to_create" "$compress"
                file_to_create="$BM_RET"

                commit_archive "$file_to_create"
        done
}

backup_method_pipe()
{
	info "Using method \"\$BM_ARCHIVE_METHOD\""
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

