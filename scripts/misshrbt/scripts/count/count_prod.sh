#!/bin/bash

# File containing list of bucket names, one per line
#bucket_file="/home/hadoop/praveen/misshrbt/inputs/miss_hrtbt.txt"
bucket_file="/home/hadoop/praveen/misshrbt/inputs/prod_path.txt"
log_file="/home/hadoop/praveen/misshrbt/logs/count_log.txt"
# Read bucket names from the file into an array
buckets=()
while IFS= read -r bucket_name; do
    buckets+=("$bucket_name")
done < "$bucket_file"

# Loop through the array and check buckets
for bucket_name in "${buckets[@]}"; do
    echo "count of: $bucket_name"
    #aws s3 rb "s3://$bucket_name"
    echo "object count of $bucket_name is: "  >> $log_file
    aws s3 ls $bucket_name --recursive  --recursive --human-readable --summarize | grep "Total Objects*" >> $log_file
done
