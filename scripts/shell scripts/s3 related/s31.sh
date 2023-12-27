#!/bin/bash
aws s3api list-buckets --query Buckets[].Name >> buckets.csv
#  need to remove these chars from above file  []",
awk '{gsub(/[|]|"|,/,"")}1' buckets.csv > buckets.txt

## to get the buckets volume and no of objects
file=bucket.txt
for bucket in `cat $file`
do
echo "$bucket"
aws s3 ls s3://$bucket --recursive  --human-readable --summarize | grep "Total Size*" >> vol.csv
continue
aws s3 ls s3://$bucket --recursive  --human-readable --summarize | grep "Total Objects*" >> obj.csv
#break
#we have bucket list and thier volumes now we have merge the files now
paste buc.txt vol.csv obj.csv > dev.csv
#
cat dev.csv | awk -F'/' '{print $1 "\t" $3}' > dev1.csv
#
awk 'BEGIN {FS=":" ; OFS=" " } {print $1,$2,$3}' dev1.csv >> s3bucketvol.csv
done