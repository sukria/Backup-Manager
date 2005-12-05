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
# This is upload methods library.

# Reads the configuration keys in order to set the 
# environement (hosts, sources, ...)
bm_upload_init()
{
    hosts="$1"
    bm_upload_hosts=$(echo $hosts| sed -e 's/ /,/g')
    
    v_switch=""
    if [ "$verbose" == "true" ]; then
        v_switch="-v"
    fi

}

# Manages SSH uploads
bm_upload_ssh()
{
    info "Using the upload method \"ssh\"."
    
    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_SSH_HOSTS"
    bm_upload_init "$bm_upload_hosts"

    if [ -z "$BM_UPLOAD_SSH_DESTINATION" ]; then
        BM_UPLOAD_SSH_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        
    if [ -z "$BM_UPLOAD_SSH_DESTINATION" ]; then
        error "No valid destination found, SSH upload not possible."
    fi        
    
    # the flags for the SSH method
    k_switch=""
    if [ ! -z "$BM_UPLOAD_SSH_KEY" ]; then
        k_switch="-k=\"$BM_UPLOAD_SSH_KEY\""
    fi

    # Call to backup-manager-upload
    su $BM_UPLOAD_SSH_USER -s /bin/sh -c \
    "$bmu $v_switch \
          $k_switch \
          -m=\"scp\" \
          -h=\"$bm_upload_hosts\" \
          -u=\"$BM_UPLOAD_SSH_USER\" \
          -d=\"$BM_UPLOAD_SSH_DESTINATION\" \
          -r=\"$BM_REPOSITORY_ROOT\" today" || 
    error "Unable to call backup-manager-upload."
}

# Manages FTP uploads
bm_upload_ftp()
{
    info "Using the upload method \"ftp\"."

    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_FTP_HOSTS"
    bm_upload_init "$bm_upload_hosts" 
    
    if [ -z "$BM_UPLOAD_FTP_DESTINATION" ]; then
        BM_UPLOAD_FTP_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        

    if [ -z "$BM_UPLOAD_FTP_DESTINATION" ]; then
        error "No valid destination found, FTP upload not possible."
    fi        

    # flags for the FTP method
    ftp_purge_switch=""
    if [ "$BM_UPLOAD_FTPPURGE" == "yes" ] || 
       [ "$BM_UPLOAD_FTPPURGE" = "true" ]; then
            ftp_purge_switch="--ftp-purge"
    fi
 
    $bmu $v_switch $ftp_purge_switch \
        -m="ftp" \
        -h="$bm_upload_hosts" \
        -u="$BM_UPLOAD_FTP_USER" \
        -p="$BM_UPLOAD_FTP_PASSWORD" \
        -d="$BM_UPLOAD_FTP_DESTINATION" \
        -r="$BM_REPOSITORY_ROOT" today || 
    error "unable to call backup-manager-upload"

}

# Manages RSYNC uploads
bm_upload_rsync_common()
{
    
    bm_upload_hosts="$BM_UPLOAD_HOSTS $BM_UPLOAD_RSYNC_HOSTS"
    bm_upload_init "$bm_upload_hosts"

    if [ -z "$BM_UPLOAD_RSYNC_DESTINATION" ]; then
        BM_UPLOAD_RSYNC_DESTINATION="$BM_UPLOAD_DESTINATION"
    fi        
    if [ -z "$BM_UPLOAD_RSYNC_DESTINATION" ]; then
        error "No valid destination found, RSYNC upload not possible."
    fi

  rsync_options="-va"
  if [ ! -z $BM_RSYNC_DUMPSYMLINKS ]; then
    if [ "$BM_RSYNC_DUMPSYMLINKS" = "yes" ] ||
       [ "$BM_RSYNC_DUMPSYMLINKS" = "true" ]; then
      rsync_options="-vaL"
    fi
  fi

  for DIR in $BM_RSYNC_DIRECTORIES
  do
    if [ -n "$bm_upload_hosts" ]
    then
      if [ ! -z "$BM_UPLOAD_SSH_KEY" ]; then
        servers=`echo $bm_upload_hosts| sed 's/ /,/g'`
        for SERVER in $servers
        do
          ${rsync} ${rsync_options} -e "ssh -i ${BM_UPLOAD_SSH_KEY}" ${DIR} ${BM_UPLOAD_SSH_USER}@${SERVER}:$BM_UPLOAD_RSYNC_DESTINATION/${RSYNC_SUBDIR}/
        done
      else
        info "Need a key to use rsync"
      fi
    fi
  done
}

bm_upload_rsync()
{
  info "Using the upload method \"rsync\"."
  RSYNC_SUBDIR=""
  bm_upload_rsync_common
}

bm_upload_rsync-snapshots()
{
  info "Using the upload method \"rsync-snapshots\"."
  RSYNC_SUBDIR=${TODAY}
  bm_upload_rsync_common
}
