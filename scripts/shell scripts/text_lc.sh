#!/bin/bash
file=buckets.txt
for bucket in `cat $file`
do
echo "$bucket" >> lifecycle.csv | aws s3api get-bucket-lifecycle --bucket ${bucket} >> lifecycle.csv
done