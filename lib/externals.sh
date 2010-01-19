# All external programs used must be initialized here
zip=$(which zip 2> /dev/null) || true
bzip=$(which bzip2 2> /dev/null) || true
gzip=$(which gzip 2> /dev/null) || true
gpg=$(which gpg 2> /dev/null) || true
lzma=$(which lzma 2> /dev/null) || true
dar=$(which dar 2> /dev/null) || true
tar=$(which tar 2> /dev/null) || true
rsync=$(which rsync 2> /dev/null) || true
mkisofs=$(which mkisofs 2> /dev/null) || mkisofs=$(which genisoimage 2> /dev/null) || true
growisofs=$(which growisofs 2> /dev/null) || true
dvdrwformat=$(which dvd+rw-format 2> /dev/null) || true
cdrecord=$(which cdrecord 2> /dev/null) || cdrecord=$(which wodim 2> /dev/null) || true
md5sum=$(which md5sum 2> /dev/null) || true
bc=$(which bc 2> /dev/null) || true
mysqldump=$(which mysqldump 2> /dev/null) || true
svnadmin=$(which svnadmin 2> /dev/null) || true
logger=$(which logger 2> /dev/null) || true
nice_bin=$(which nice 2> /dev/null) || true
