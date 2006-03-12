# Copyright (C) 2005 The Backup Manager Authors
#
# See the AUTHORS file for details.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
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
    if [ "$verbose" = "true" ]; then
        echo "$str ${md5hash})"
    fi

	md5file="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${TODAY}.md5"

	# Check if the md5file contains already the md5sum of the file_to_create.
	# In this case, the new md5sum overwrites the old one.
	if grep "$base" $md5file >/dev/null 2>&1 ; then
		previous_md5sum=$(get_md5sum_from_file $base $md5file)
		sed -e "/$base/s/$previous_md5sum/$md5hash/" -i $md5file
	else
		echo "$md5hash  $base" >> $md5file
	fi

    # Now that the file is created, remove previous duplicates if exists...
    purge_duplicate_archives $file_to_create || 
        error "Unable to purge duplicates of \$file_to_create"

    # security fixes if BM_REPOSITORY_SECURE is set to true
    if [ $BM_REPOSITORY_SECURE = true ]; then
        chown $BM_REPOSITORY_USER:$BM_REPOSITORY_GROUP $file_to_create
        chmod 660 $file_to_create
    fi
}

commit_archives()
{    
	file_to_create="$1"
    if [ "$BM_TARBALL_FILETYPE" = "dar" ]; then
        for dar_file in $file_to_create.*.dar
        do
            commit_archive "$dar_file"
        done
    else
        commit_archive "$file_to_create"
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
    words=0

    if [ -f $file_to_create ] && [ $force != true ] 
    
    then
        warning "File \$file_to_create already exists, skipping."
        export BM_RET=""
    else
        logfile=$(mktemp /tmp/bm-command.XXXXXX)

        case "$compress" in
        "gzip"|"gz")
            if [ -x $gzip ]; then
                $command 2>$logfile | $gzip -f -q -9 > "$file_to_create.gz"
                words=$(wc -w $logfile | awk '{print $1}')
                if [ $words -gt 0 ]; then
                    warning "Unable to exec \$command; check \$logfile"
                else
                    rm -f $logfile
                fi
                file_to_create="$file_to_create.gz"
            else
                error "Compressor \$compress requires \$gzip."
            fi
        ;;
        "bzip"|"bzip2")
            if [ -x $bzip ]; then
                $command 2>$logfile | $bzip -f -q -9 > "$file_to_create.bz2"
                words=$(wc -w $logfile | awk '{print $1}')
                if [ $words -gt 0 ]; then
                    warning "Unable to exec \$command; check \$logfile"
                else
                    rm -f $logfile
                fi
                file_to_create="$file_to_create.bz2"
            else
                error "Compressor \$compress requires \$bzip."
            fi
        ;;
        ""|"uncompressed"|"none")
            $command 1> $file_to_create 2>$logfile
            words=$(wc -w $logfile | awk '{print $1}')
            if [ $words -gt 0 ]; then
                warning "Unable to exec \$command; check \$logfile"
            else
                rm -f $logfile
            fi
        ;;
        *)
            error "No such compressor supported: \$compress."
        ;;
        esac

        # make sure we didn't loose the archive
        if [ ! -e $file_to_create ]; then
            error "Unable to find \$file_to_create" 
        fi
        export BM_RET="$file_to_create"
    fi
}

__create_file_with_meta_command()
{
    __exec_meta_command "$command" "$file_to_create" "$compress"
    file_to_create="$BM_RET"
    if [ -n "$BM_RET" ]; then
        commit_archive "$file_to_create"
    fi
}

__get_flags_tar_blacklist()
{
    blacklist=""
	for pattern in $BM_TARBALL_BLACKLIST
	do
		blacklist="$blacklist --exclude=$pattern"
	done
    echo "$blacklist"
}

# Thanks to Michel Grentzinger for his 
# smart ideas/remarks about that function.
__get_flags_dar_blacklist()
{
    target="$1"
    target=${target%/}
    blacklist=""
	for pattern in $BM_TARBALL_BLACKLIST
	do
        # absolute paths 
        char=$(expr substr $pattern 1 1)
        if [ "$char" = "/" ]; then

           # we blacklist only absolute paths related to $target
           if [ "${pattern#$target}" != "$pattern" ]; then
                
                # making a relative path...
                pattern="${pattern#$target}"
                length=$(expr length $pattern)
                pattern=$(expr substr $pattern 2 $length)

                # ...and blacklisting it
                blacklist="$blacklist -P $pattern"
           fi

        # relative path are blindly appended to the blacklist
        else
            blacklist="$blacklist -P $pattern"
        fi
    done
    echo "$blacklist"
}

__get_flags_zip_dump_symlinks()
{
    export ZIP="" 
    export ZIPOPT="" 
	y="-y"
	if [ "$BM_TARBALL_DUMPSYMLINKS" = "true" ]; then
		y=""
	fi
    echo "$y"
}

__get_flags_tar_dump_symlinks()
{
	h=""
	if [ "$BM_TARBALL_DUMPSYMLINKS" = "true" ]; then
		h="-h "
	fi
    echo "$h"
}

__get_file_to_create()
{
    target="$1"
    dir_name=$(get_dir_name $target $BM_TARBALL_NAMEFORMAT)
    file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$TODAY.$BM_TARBALL_FILETYPE"
    # dar appends itself the ".dar" extension
    if [ "$BM_TARBALL_FILETYPE" = "dar" ]; then
        file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$TODAY"
    fi
    echo "$file_to_create"
}

function __get_master_day()
{
    if [ -z "$BM_TARBALLINC_MASTERDATETYPE" ]; then
        error "No frequency given, set BM_TARBALLINC_MASTERDATETYPE."
    fi
    
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
}

function __init_masterdatevalue()
{
    if [ -z "$BM_TARBALLINC_MASTERDATEVALUE" ]; then
        BM_TARBALLINC_MASTERDATEVALUE="1"
    fi
}

function __get_flags_tar_incremental()
{
    dir_name="$1"
    incremental_list="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.incremental-list.txt"
    
    incremental=""
    __get_master_day
    __init_masterdatevalue

    # if master day, we have to purge the incremental list if exists
    # so we'll generate a new one (and then, a full backup).
    if [ "$master_day" = "$BM_TARBALLINC_MASTERDATEVALUE" ] && [ -e $incremental_list ]; then
        info "Making master backups."
        rm -f $incremental_list
    fi
    incremental="--listed-incremental $incremental_list"

}

function __get_flags_dar_incremental()
{
    dir_name="$1"
    incremental=""
    __get_master_day
    __init_masterdatevalue
    yesterday=$(date +'%Y%m%d' --date '1 days ago')
    yesterday_dar="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$yesterday.dar"
    yesterday_dar_first="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$yesterday.1.dar"

    # If we aren't the "full backup" day, we take the previous backup as 
    # a reference for the incremental stuff.
    # We have to find the previous backup for that...
    if [ "$master_day" != "$BM_TARBALLINC_MASTERDATEVALUE" ]; then
        if [ -e $yesterday_dar ] || [ -e $yesterday_dar_first ]; then
            incremental="--ref $BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$yesterday"
        else
            incremental=""
        fi
    fi
}

__get_flags_dar_maxsize()
{
    if [ -n "$BM_TARBALL_SLICESIZE" ]; then
        maxsize="--alter=SI -s $BM_TARBALL_SLICESIZE"
    fi
    echo "$maxsize"
}

__get_flags_dar_overwrite()
{
	if [ $force = true ] ; then
		overwrite="-w"
	fi
	
	echo "$overwrite"
}

__get_backup_tarball_command()
{
    case $BM_TARBALL_FILETYPE in
        tar) 
            command="$tar $incremental $blacklist $dumpsymlinks -p -c    -f "$file_to_create" "$target""
        ;;
        tar.gz)
            command="$tar $incremental $blacklist $dumpsymlinks -p -c -z -v -f "$file_to_create" "$target""
        ;;
        tar.bz2|tar.bz) 
            command="$tar $incremental $blacklist $dumpsymlinks -p -c -j -f "$file_to_create" "$target""
        ;;
        zip) 
            command="$zip $dumpsymlinks -r "$file_to_create" "$target""
        ;;
        dar)
            blacklist=""
            blacklist="$(__get_flags_dar_blacklist "$target")"
            command="$dar $incremental $blacklist $maxsize $overwrite -z9 -Q -c "$file_to_create" -R "$target""
        ;;
        *)
            return 1
        ;;
    esac
    echo "$command"
}

__make_tarball_archives()
{
    nb_err=0
	for target in $BM_TARBALL_DIRECTORIES
	do
        # first be sure the target exists
		if [ ! -e $target ] || [ ! -r $target ]; then
			warning "Target \$target does not exist, skipping."
			nb_err=$(($nb_err + 1))
			continue
		fi
		
        dir_name=$(get_dir_name "$target" $BM_TARBALL_NAMEFORMAT)
        file_to_create=$(__get_file_to_create "$target")
    
        # handling of incremental options
        incremental=""
        if [ $method = tarball-incremental ]
        then
            case $BM_TARBALL_FILETYPE in
                dar)
                    __get_flags_dar_incremental $dir_name
                ;;
                
                *)
                    if [ "$BM_TARBALL_FILETYPE" != "zip" ]; then
                        __get_flags_tar_incremental "$dir_name"
                    fi
                ;;
            esac
        fi
        command=$(__get_backup_tarball_command) || 
            error "The filetype \$BM_TARBALL_FILETYPE is not supported."


        # dar is not like tar, we have to manually check for existing .1.dar files
        if [ $BM_TARBALL_FILETYPE = dar ]; then
            file_to_check="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$dir_name.$TODAY.1.dar"
        else
            file_to_check="$file_to_create"
        fi
        
        if [ ! -e $file_to_check ] || [ $force = true ]; then
            logfile=$(mktemp /tmp/bm-tarball.log.XXXXXX)
#            __debug "$command"
            if ! $command > $logfile 2>&1 ; then
                handle_tarball_error "$file_to_create" "$logfile"
            else
                rm -f $logfile
                commit_archives "$file_to_create"
            fi
        else
            warning "File \$file_to_check already exists, skipping."
            continue
        fi
    done
}

# This manages both "tarball" and "tarball-incremental" methods.
# configuration keys: BM_TARBALL_* and BM_TARBALLINC_*
backup_method_tarball()
{
    method="$1"
	info "Using method \"\$method\"."
	
    # build the command line
    case $BM_TARBALL_FILETYPE in 
    tar.gz)
        blacklist="$(__get_flags_tar_blacklist)"
        dumpsymlinks="$(__get_flags_tar_dump_symlinks)"
    ;;
    tar)
        blacklist="$(__get_flags_tar_blacklist)"
        dumpsymlinks="$(__get_flags_tar_dump_symlinks)"
    ;;
    tar.bz2|tar.bz)
        blacklist="$(__get_flags_tar_blacklist)"
        dumpsymlinks="$(__get_flags_tar_dump_symlinks)"
    ;;
    zip)
        dumpsymlinks="$(__get_flags_zip_dump_symlinks)"
    ;;
    dar)
        maxsize="$(__get_flags_dar_maxsize)"
        overwrite="$(__get_flags_dar_overwrite)"
    ;;
    esac

    __make_tarball_archives
	
    # Handle errors
	if [ $nb_err -gt 0 ]; then
		error "During the tarballs generation, \$nb_err error(s) occurred."
	fi
}

backup_method_mysql()
{
    method="$1"
	info "Using method \"\$method\"."
	if [ ! -x $mysqldump ]; then
		error "The \"mysql\" method is chosen, but \$mysqldump is not found."
	fi

    opt=""
    if [ "$BM_MYSQL_SAFEDUMPS" = "true" ]; then
        opt="--opt"
    fi
    
    base_command="$mysqldump $opt -u$BM_MYSQL_ADMINLOGIN -p$BM_MYSQL_ADMINPASS -h$BM_MYSQL_HOST -P$BM_MYSQL_PORT"
    compress="$BM_MYSQL_FILETYPE"	

    for database in $BM_MYSQL_DATABASES
    do
        if [ "$database" = "__ALL__" ]; then
            file_to_create="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-all-mysql-databases.$TODAY.sql"
            command="$base_command --all-databases"
        else
            file_to_create="$BM_REPOSITORY_ROOT/${BM_ARCHIVE_PREFIX}-${database}.$TODAY.sql"
            command="$base_command $database"
        fi
        __create_file_with_meta_command
    done   
}

backup_method_svn()
{
    method="$1"
    info "Using method \"\$method\"."
    if [ ! -x $svnadmin ]; then
        error "The \"svn\" method is chosen, but \$svnadmin is not found."
    fi

    for repository in $BM_SVN_REPOSITORIES
    do
        if [ ! -d $repository ]; then
            warning "SVN repository \"\$repository\" is not valid; skipping."
        else
            archive_name=$(get_dir_name $repository "long")
            file_to_create="$BM_REPOSITORY_ROOT/$BM_ARCHIVE_PREFIX$archive_name.$TODAY.svn"
            command="$svnadmin dump $repository"
            compress="$BM_SVN_COMPRESSWITH"
            __create_file_with_meta_command
        fi
    done
}

backup_method_pipe()
{
    method="$1"
    info "Using method \"\$method\"."
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
        __create_file_with_meta_command || error "Cannot create archive."

        # update the index mark 
        index=$(($index + 1))
    done
}

