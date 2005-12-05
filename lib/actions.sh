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
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Major features of backup manager are here.

# Loop on the backup methods
make_archives()
{
	for method in $BM_ARCHIVE_METHOD
	do		
		case $method in
		mysql)
			backup_method_mysql
		;;
		tarball|tarball-incremental)
			backup_method_tarball
		;;
        pipe)
            backup_method_pipe
        ;;
        svn)
            backup_method_svn
        ;;
        *)
            error "No such backup method: \$BM_ARCHIVE_METHOD"
        ;;
    esac
done
}

# Loop on the upload methods
upload_files ()
{
    for method in $BM_UPLOAD_METHOD
    do            
        case $method in
        ftp|FTP)
            bm_upload_ftp
        ;;
        ssh|SSH|scp|SCP)
            bm_upload_ssh
        ;;
        rsync|RSYNC)
            bm_upload_rsync
        ;;
        rsync-snapshots|RSYNC-SNAPSHOTS)
            bm_upload_rsync_snapshots
        ;;
        *)
            warning "The upload method \"\$method\" is not supported; skipping."
        ;;
        esac
    done        
}

# This will get all the md5 sums of the day,
# mount the BM_BURNING_DEVICE on /tmp/device and check 
# that the files are correct with md5 tests.
check_cdrom_md5_sums()
{
	has_error=0

	if [ -z $BM_BURNING_DEVICE ]; then
		error "MD5 checkup is only performed on CD media. Please set the BM_BURNING_DEVICE in $conffile."
	fi

	# first create the mount point
	mount_point="$(mktemp -d /tmp/bm-mnt.XXXXXX)"
	if [ ! -d $mount_point ]; then
		error "The mount point \$mount_point is not there"
	fi
	
	# mount the device in /tmp/
	info -n "Mounting \$BM_BURNING_DEVICE: "
	mount $BM_BURNING_DEVICE $mount_point >& /dev/null || error "unable to mount \$BM_BURNING_DEVICE on \$mount_point"
	info "ok"
	export HAS_MOUNTED=1
	
	# now we can check the md5 sums.
	for file in $mount_point/*
	do
		base_file=$(basename $file)
		date_of_file=$(get_date_from_file $file)
		prefix_of_file=$(get_prefix_from_file $file)
		info -n "Checking MD5 sum for \$base_file: "
		
		# Which file should contain the MD5 hashes for that file ?
		md5_file="$BM_REPOSITORY_ROOT/${prefix_of_file}-${date_of_file}.md5"

		# if it does not exists, we create it (yes that will take much time).
		if [ ! -f $md5_file ]; then
			save_md5_sum $file $md5_file || continue
		fi
		
		# try to read the previously saved md5 hash in the file
		md5hash_trust=$(get_md5sum_from_file ${base_file} $md5_file)

		# If the MD5 hash was not found, generate it and save it now.
		if [ -z "$md5hash_trust" ]; then
			save_md5_sum $file $md5_file || continue
			md5hash_trust=$(get_md5sum_from_file ${base_file} $md5_file)
		fi
		
		md5hash_cdrom=$(get_md5sum $file) || md5hash_cdrom="undefined"
		case "$md5hash_cdrom" in
			"$md5hash_trust")
				info "ok"
			;;
			"undefined")
				info "failed (read error)"
				has_error=1
			;;
			*)
				info "failed (MD5 hash mismatch)"
				has_error=1
			;;
		esac
	done

	if [ $has_error = 1 ]; then
		error "Errors encountered during MD5 controls."
	fi

	# remove the mount point
	umount $BM_BURNING_DEVICE || error "unable to unmount the mount point \$mount_point"
	rmdir $mount_point || error "unable to remove the mount point \$mount_point"
}

# this will try to burn the generated archives to the media
# choosed in the configuration.
# Obviously, we will use mkisofs for generating the iso and 
# cdrecord for burning CD, growisofs for the DVD.
# Note that we pipe the iso image directly to cdrecord
# in this way, we prevent the use of preicous disk place.
burn_files()
{
	if [ "$BM_BURNING" != "yes" ]; then
		return 0
	fi
	
	# determine what to burn according to the size...
	what_to_burn=""
	size=$(size_of_path "$BM_REPOSITORY_ROOT")
	if [ $size -gt $BM_BURNING_MAXSIZE ]; then
		size=$(size_of_path "${BM_REPOSITORY_ROOT}/*${TODAY}*")
		if [ $size -gt $BM_BURNING_MAXSIZE ]; then
			error "Cannot burn archives of the \$TODAY, too big: \${size}M, must fit in \$BM_BURNING_MAXSIZE"
		else
			# let's take all the regular files from today
			for file in ${BM_REPOSITORY_ROOT}/*${TODAY}*
			do
				# we only take the regular files, not the symlinks
				if [ ! -L $file ]; then
					what_to_burn="$what_to_burn $file"
				fi
			done		
		fi
	else
		# let's take all the regular files from today
		for file in ${BM_REPOSITORY_ROOT}
		do
			# we only take the regular files, not the symlinks
			if [ ! -L $file ]; then
				what_to_burn="$what_to_burn $file"
			fi
		done		
	fi

	title="Backups of ${TODAY}"
	
	# Let's unmount the device first
	if grep $BM_BURNING_DEVICE /etc/mtab >/dev/null 2>&1; then
		info "\$BM_BURNING_DEVICE is mounted, unmounting before the burning session."
		umount $BM_BURNING_DEVICE || warning "Unable to unmount the device \$BM_BURNING_DEVICE"
	fi
	
	# get a log file in a secure path
	logfile="$(mktemp /tmp/bm-cdrecord.log.XXXXXX)"
	info "Redirecting burning logs into \$logfile"
	
	# set the cdrecord command 
	devforced=""
	if [ -n "$BM_BURNING_DEVFORCED" ]; then
		info "Forcing dev=${BM_BURNING_DEVFORCED} for cdrecord commands"
		devforced="dev=${BM_BURNING_DEVFORCED}"
	fi
	
	# burning the iso with the user choosen method
	case "$BM_BURNING_METHOD" in
		"DVD")
            if [ ! -x $growisofs ]; then
            error "DVD burning requires $growisofs, aborting."
            fi
                        
			info -n "Exporting archives to the DVD media in \$BM_BURNING_DEVICE: "
			$growisofs -Z ${BM_BURNING_DEVICE} -R -J -V "${title}" ${what_to_burn} > ${logfile} 2>&1 ||
                                error "failed, check \$logfile"
			info "ok"
		;;
		"CDRW")
            if [ ! -x $cdrecord ]; then
                error "CDROM burning requires $cdrecord, aborting."
            fi
                        
			info -n "Blanking the CDRW in \$BM_BURNING_DEVICE: "
			${cdrecord} -tao $devforced blank=fast > ${logfile} 2>&1 ||
				error "failed, check \$logfile"
			info "ok"
			
			info -n "Burning data to \$BM_BURNING_DEVICE: "
			${mkisofs} -V "${title}" -q -R -J ${what_to_burn} | \
			${cdrecord} -tao $devforced - > ${logfile} 2>&1 ||
				error "failed, check \$logfile"
			info "ok"
		;;
		"CDR")

        if [ ! -x $cdrecord ]; then
            error "CDROM burning requires $cdrecord, aborting."
        fi

			info -n "Burning data to \$BM_BURNING_DEVICE: "
			${mkisofs} -V "${title}" -q -R -J ${what_to_burn} | \
			${cdrecord} -tao $devforced - > ${logfile} 2>&1 ||
				error "failed, check \$logfile"
			info "ok"
		;;
        *)
            error "The requested burning method is not supported, check BM_BURNING_METHOD in \$conffile"
        ;;
	esac
	
	# Cleaning the logile, everything was fine at this point.
	rm -f $logfile

	# checking the files in the CDR if wanted
	if [ $BM_BURNING_CHKMD5 = yes ] 
	then
		check_cdrom_md5_sums
	fi
}

# This will parse all the files contained in BM_REPOSITORY_ROOT
# and will clean them up. Using clean_directory() and clean_file().
clean_repositories()
{
	info "Cleaning \$BM_REPOSITORY_ROOT"
	clean_directory $BM_REPOSITORY_ROOT
}


# This will run the pre-command given.
# If this command prints on STDOUT "false", 
# backup-manager will stop here.
exec_pre_command()
{
	if [ ! -z "$BM_PRE_BACKUP_COMMAND" ]; then
		info -n "Running pre-command: \$BM_PRE_BACKUP_COMMAND: "
		RET=`$BM_PRE_BACKUP_COMMAND` || RET="false" 
		case "$RET" in
			"false")
				info "failed"
				warning "pre-command returned false. Stopping the process."
				_exit 0
			;;

			*)
				info "ok"
			;;
		esac
	fi

}

exec_post_command()
{
	if [ ! -z "$BM_POST_BACKUP_COMMAND" ]; then
		info -n "Running post-command: \$BM_POST_BACKUP_COMMAND: "
		RET=`$BM_POST_BACKUP_COMMAND` || RET="false"
		case "$RET" in
			"false")
				info "failed"
				warning "post-command returned false."
			;;

			*)
				info "ok"
			;;
		esac
	fi
}
