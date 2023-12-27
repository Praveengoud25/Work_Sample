#!/bin/bash
aws s3api list-buckets --query Buckets[].Name >> buckets.csv
#  need to remove these chars from above file  []",
awk '{gsub(/[|]|"|,/,"")}1' buckets.csv > buckets.txt