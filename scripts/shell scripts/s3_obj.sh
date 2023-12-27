#!/bin/bash
file=buckets.txt
for bucket in `cat $file`
do
echo "$bucket"
aws s3 ls s3://$bucket --recursive  --human-readable --summarize | grep "Total Size*" >> obj.csv
done