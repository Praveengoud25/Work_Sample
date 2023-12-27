#!/bin/sh

#input_file = "./s3uris.txt"

while read -r line
do		
	# download to local
	aws s3 cp $line ./tmp/
	if [ $? -eq 0 ]; then
		echo "Download success for $line" >> ./download_logs.txt
	else
		echo "Download fail for $line" >> ./download_logs.txt
		rm -rf ./tmp/
		exit
	fi
	
	# validation
	details=`aws s3 ls $line`
	echo $details >> ./download_logs.txt
	
	# get file name from tmp or s3
	file_name=$(echo $details | awk '{ print $4; }')
	
	# get last modified from s3. UNUSED RIGHT NOW
	last_modified_date=$(echo $details | awk '{ print $1; }')
	last_modified_time=$(echo $details | awk '{ print $2; }')
	
	# get file size from s3
	s3_file_size=$(echo $details | awk '{ print $3; }')
	echo "File size from S3: $s3_file_size"
	
	# get file size from tmp
	local_file_size=$(wc -c ./tmp/$file_name | awk '{ print $1; }')
	echo "File size from local: $local_file_size"
	
	# compare file size if file size is not equal, exit program
	if [[ "$s3_file_size" == "$local_file_size" ]]; then
		echo "File sizes are identical between S3 and local for $line" >> ./download_logs.txt
	else
		echo "File sizes are not identical between S3 and local for $line" >> ./download_logs.txt
		rm -rf ./tmp/
		exit
	fi
	
	# where to store the backup copy
	temp_prefix="s3://ge-power-cust-prod-mnd-test20/backup-replication-ed/"
	temp_prefix_with_file="$temp_prefix${line:5}"
	
	# download to spare s3 bucket
	aws s3 cp $line $temp_prefix_with_file --sse aws:kms --sse-kms-key-id 94ca1e91-52a1-4a34-937f-d2364122adeb
	if [ $? -eq 0 ]; then
		echo "Backup copy made of $line in temporary S3 prefix $temp_prefix_with_file" >> ./download_logs.txt
	else
		echo "Creating backup copy failed for $line" >> ./download_logs.txt
		rm -rf ./tmp/
		exit
	fi
	
	
	# upload and cleanup
	aws s3 cp "./tmp/$file_name" $line --acl bucket-owner-full-control --sse aws:kms --sse-kms-key-id 94ca1e91-52a1-4a34-937f-d2364122adeb
	if [ $? -eq 0 ]; then
		echo "Upload success for $line" >> ./upload_logs.txt
		rm -rf ./tmp/
		aws s3 rm $temp_prefix_with_file
	else
		echo "Upload fail for $line" >> ./upload_logs.txt
		rm -rf ./tmp/
		exit
	fi
done < "./s3uris.txt"