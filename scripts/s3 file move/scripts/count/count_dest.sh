#!/bin/bash
log_file="$pwd../log/count_log.txt"
bucket_name="s3://usw02-prd-pwr-s3-intermittent-compaction-serverless/missing_buckets/ge-power-cust-prod-dummy/"
echo "count of: $bucket_name"
echo "object count of $bucket_name is: "  >> $log_file
aws s3 ls $bucket_name  --recursive --human-readable --summarize | grep "Total Objects*" >> $log_file