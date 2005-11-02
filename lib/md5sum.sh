#
# The backup-manager's md5sum.sh library.
#
# Everything related to md5sum is here.

# This will get a filename a will search its 
# md5hash in the file given as second arg.
get_md5sum_from_file()
{
	filename="$1"
	md5file="$2"

	if [ ! -f $md5file ]; then
		error "No md5file found: \$md5file"
	fi
	
	OLDIFS=$IFS
	IFS=$'\n'
	for line in `cat $md5file`
	do
		hash=$(echo $line | awk '{print $1}')
		file=$(echo $line | awk '{print $2}')
		if [ "$file" = "$filename" ]; then
			echo $hash
			break
		fi
	done
	IFS=$OLDIFS
}

# Just return the md5 hash of a file
get_md5sum()
{
	file="$1"
	if [ -f $file ]; then
		md5=`$md5sum $file 2>/dev/null` || md5=""
		if [ -z "$md5" ]; then
			echo "undefined"
		else
			md5=$(echo $md5 | awk '{print $1}')
			echo "$md5"
		fi
	else
		echo "undefined"
	fi
}

# Will take an archive path and the path
# to a MD5 file.
# It will put the md5sum output inside.
# Note that the base name is extracted from
# the given archive path in order to get the 
# MD5 hash from the BM_REPOSITORY_ROOT.
# 
save_md5_sum()
{
	archive="$1"
	archive=$(basename $archive)
	archive="$BM_REPOSITORY_ROOT/$archive"
	md5file="$2"
	if [ -f $archive ]; then
		hash=$(get_md5sum $archive)
		base=$(basename $archive)
		echo "$hash  $base" >> $md5file
	else
		warning "Archive given does not exist in the repository: \$archive"
	fi
}

