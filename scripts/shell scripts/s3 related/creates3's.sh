#!/bin/bash

# File containing list of bucket names, one per line
bucket_file="bucketlist.txt"

# Read bucket names from the file into an array
buckets=()
while IFS= read -r bucket_name; do
    buckets+=("$bucket_name")
done < "$bucket_file"

# Loop through the array and create buckets
for bucket_name in "${buckets[@]}"; do
    echo "Creating bucket: $bucket_name"
    #aws s3 rm "s3://$bucket_name" --recursive
    #aws s3 rb "s3://$bucket_name"
    aws s3api create-bucket --bucket "$bucket_name"
done

echo "All buckets created successfully."