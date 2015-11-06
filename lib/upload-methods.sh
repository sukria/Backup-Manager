# Copyright (C) 2010 The Backup Manager Authors
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
# This is upload methods library.

# Reads the configuration keys in order to set the 
# environement (hosts, sources, ...)
function bm_upload_init()
{
    hosts="$1"
    bm_upload_hosts=$(echo $hosts| sed -e 's/ /,/g')
    
    v_switch=""
    if [[ "$verbose" == "true" ]]; then
        v_switch="-v"
    fi

}

# Manages SSH uploads
function bm_upload_ssh()
{
    info "Using the upload method \"ssh\"."
    
    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_SSH_HOSTS"
    bm_upload_init "$bm_upload_hosts"

    if [[ -z "$BM_UPLOAD_SSH_DESTINATION" ]]; then
        BM_UPLOAD_SSH_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        
    if [[ -z "$BM_UPLOAD_SSH_DESTINATION" ]]; then
        error "No valid destination found, SSH upload not possible."
    fi        
    
    # the flags for the SSH method
    k_switch=""
    if [[ ! -z "$BM_UPLOAD_SSH_KEY" ]]; then
        k_switch="-k=$BM_UPLOAD_SSH_KEY"
    fi

    ssh_purge_switch=""
    if [[ "$BM_UPLOAD_SSH_PURGE" = "true" ]]; then
        ssh_purge_switch="--ssh-purge"
    fi

    # Call to backup-manager-upload
    logfile="$(mktemp ${BM_TEMP_DIR}/bmu-log.XXXXXX)"
    $bmu $v_switch $k_switch $ssh_purge_switch -m="scp" \
          -h="$bm_upload_hosts" \
          -u="$BM_UPLOAD_SSH_USER" \
          -d="$BM_UPLOAD_SSH_DESTINATION" \
          -r="$BM_REPOSITORY_ROOT" ${TODAY} 2>$logfile || 
    error "Error reported by backup-manager-upload for method \"scp\", check \"\$logfile\"."
    rm -f $logfile
}


# Manages encrypted SSH uploads
function bm_upload_ssh_gpg()
{
    info "Using the upload method \"ssh-gpg\"."
    
    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_SSH_HOSTS"
    bm_upload_init "$bm_upload_hosts"

    if [[ -z "$BM_UPLOAD_SSH_DESTINATION" ]]; then
        BM_UPLOAD_SSH_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        
    if [[ -z "$BM_UPLOAD_SSH_DESTINATION" ]]; then
        error "No valid destination found, SSH upload not possible."
    fi        
    if [[ -z "$BM_UPLOAD_SSHGPG_RECIPIENT" ]]; then
        error "No gpg recipient given. Argument is mandatory if upload method ssh-gpg is used."
    fi

    # the flags for the SSH method
    k_switch=""
    if [[ ! -z "$BM_UPLOAD_SSH_KEY" ]]; then
        k_switch="-k=$BM_UPLOAD_SSH_KEY"
    fi

    # Call to backup-manager-upload
    logfile="$(mktemp ${BM_TEMP_DIR}/bmu-log.XXXXXX)"
    $bmu $v_switch $k_switch -m="ssh-gpg" \
         -h="$bm_upload_hosts" \
         -u="$BM_UPLOAD_SSH_USER" \
         -d="$BM_UPLOAD_SSH_DESTINATION" \
         -r="$BM_REPOSITORY_ROOT" \
         --gpg-recipient="$BM_UPLOAD_SSHGPG_RECIPIENT" ${TODAY} 2>$logfile|| 
    error "Error reported by backup-manager-upload for method \"ssh-gpg\", check \"\$logfile\"."
    rm -f $logfile
}

# Manages FTP uploads
function bm_upload_ftp()
{
    info "Using the upload method \"ftp\"."

    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_FTP_HOSTS"
    bm_upload_init "$bm_upload_hosts" 
    
    if [[ -z "$BM_UPLOAD_FTP_DESTINATION" ]]; then
        BM_UPLOAD_FTP_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        

    if [[ -z "$BM_UPLOAD_FTP_DESTINATION" ]]; then
        error "No valid destination found, FTP upload not possible."
    fi        

    # flags for the FTP method
    ftp_purge_switch=""
    if [[ "$BM_UPLOAD_FTP_PURGE" = "true" ]]; then
            ftp_purge_switch="--ftp-purge"
    fi

    # Additionnal flag for the FTP method
    ftp_test_switch=""
    if [[ "$BM_UPLOAD_FTP_TEST" = "true" ]]; then
            ftp_test_switch="--ftp-test"
		# create the test file
		$dd if=/dev/zero of=$BM_REPOSITORY_ROOT/2mb_file.dat bs=1M count=2 > /dev/null 2>&1
    fi
 
    logfile="$(mktemp ${BM_TEMP_DIR}/bmu-log.XXXXXX)"
    $bmu $v_switch $ftp_purge_switch $ftp_test_switch \
        -m="ftp" \
        -h="$bm_upload_hosts" \
        -u="$BM_UPLOAD_FTP_USER" \
        -d="$BM_UPLOAD_FTP_DESTINATION" \
        -r="$BM_REPOSITORY_ROOT" ${TODAY} 2>$logfile|| 
    error "Error reported by backup-manager-upload for method \"ftp\", check \"\$logfile\"."
    rm -f $logfile

}

# Manages S3 uploads
function bm_upload_s3()
{
    info "Using the upload method \"S3\"."

    bm_upload_hosts="s3.amazon.com"
    bm_upload_init "$bm_upload_hosts" 
    
    if [[ -z "$BM_UPLOAD_S3_DESTINATION" ]]; then
        BM_UPLOAD_S3_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        

    # flags for the S3 method
    s3_purge_switch=""
    if [[ "$BM_UPLOAD_S3_PURGE" = "true" ]]; then
        s3_purge_switch="--s3-purge"
    fi
 
    logfile="$(mktemp ${BM_TEMP_DIR}/bmu-log.XXXXXX)"
    $bmu $v_switch $s3_purge_switch \
        -m="s3" \
        -h="$bm_upload_hosts" \
        -u="$BM_UPLOAD_S3_ACCESS_KEY" \
        -b="$BM_UPLOAD_S3_DESTINATION" \
        -r="$BM_REPOSITORY_ROOT" ${TODAY} 2>$logfile || 
    error "Error reported by backup-manager-upload for method \"s3\", check \"\$logfile\"."
    rm -f $logfile
}

function _exec_rsync_command()
{
    info "Uploading \$directory to \${host}:\${BM_UPLOAD_RSYNC_DESTINATION}"
    logfile=$(mktemp ${BM_TEMP_DIR}/bm-rsync.XXXXXX)

    # default options for local rsync
    ssh_option=""
    destination_option="$BM_UPLOAD_RSYNC_DESTINATION/${RSYNC_SUBDIR%/}"
    
    # remote hosts use SSH
    if [[ "$host" != "localhost" ]]; then
        if [[ -z "$BM_UPLOAD_SSH_USER" ]] || 
           [[ -z "$BM_UPLOAD_SSH_KEY" ]]; then 
            error "Need a key to use rsync (set BM_UPLOAD_SSH_USER, BM_UPLOAD_SSH_KEY)."
        fi
        ssh_option="ssh -l ${BM_UPLOAD_SSH_USER} -p ${BM_UPLOAD_SSH_PORT} -o BatchMode=yes -o ServerAliveInterval=60 -i ${BM_UPLOAD_SSH_KEY}"
        if [[ ! -z "$BM_UPLOAD_SSH_PORT" ]]; then
        	ssh_option="${ssh_option} -p ${BM_UPLOAD_SSH_PORT}"
        fi
        destination_option="${BM_UPLOAD_SSH_USER}@${host}:${destination_option}"
    fi
    
    # Due to a very weird behaviour in the rsync's argument-processing phase;
    # it's safer to use RSYNC_RSH to pass ssh options than using the -e '' flag.
    command="${rsync_options} ${directory} ${destination_option}"
    if ! RSYNC_RSH="$ssh_option" \
         $rsync $command >$logfile 2>&1; then
        error "Upload of \$directory with rsync failed; check \$logfile."
    else
        rm -f $logfile
    fi        
}

# Manages RSYNC uploads
function bm_upload_rsync_common()
{
    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_RSYNC_HOSTS"
    bm_upload_init "$bm_upload_hosts"

    if [[ -z "$bm_upload_hosts" ]]; then
        bm_upload_hosts="localhost"
    fi
    if [[ -z "$BM_UPLOAD_RSYNC_DESTINATION" ]]; then
        BM_UPLOAD_RSYNC_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi
    if [[ -z "$BM_UPLOAD_RSYNC_DESTINATION" ]]; then
        error "No valid destination found, RSYNC upload not possible."
    fi
    
    rsync_options="-zva"
    if [[ ! -z $BM_UPLOAD_RSYNC_DUMPSYMLINKS ]]; then
        if [[ "$BM_UPLOAD_RSYNC_DUMPSYMLINKS" = "true" ]]; then
            rsync_options="-zvaL"
        fi
    fi

    if [[ ! -z $BM_UPLOAD_RSYNC_EXTRA_OPTIONS ]]; then
        rsync_options="${rsync_options} $BM_UPLOAD_RSYNC_EXTRA_OPTIONS"
    fi

    # For every exclusion defined in the configuration,
    # append an --exclude condition to the rsync command
    if [[ ! -z "$BM_UPLOAD_RSYNC_BLACKLIST" ]]; then
        for exclude in $BM_UPLOAD_RSYNC_BLACKLIST
        do
            rsync_options="${rsync_options} --exclude=${exclude}"
        done
    fi

    # Apply a bandwidth limit if required by the user
    if [[ ! -z "$BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT" ]]; then
        rsync_options="${rsync_options} --bwlimit=${BM_UPLOAD_RSYNC_BANDWIDTH_LIMIT}"
    fi

    for directory in $BM_UPLOAD_RSYNC_DIRECTORIES
    do
        if [[ -n "$bm_upload_hosts" ]]; then
            servers=`echo $bm_upload_hosts| sed 's/ /,/g'`
            for host in $servers
            do
                _exec_rsync_command
            done
        else
            warning "No hosts given to the rsync method, set BM_UPLOAD_RSYNC_HOSTS."
        fi
    done
}

function bm_upload_rsync()
{
  info "Using the upload method \"rsync\"."
  RSYNC_SUBDIR=""
  bm_upload_rsync_common
}

function bm_upload_rsync_snapshots()
{
  info "Using the upload method \"rsync-snapshots\"."
  RSYNC_SUBDIR=${TODAY}
  bm_upload_rsync_common
}
