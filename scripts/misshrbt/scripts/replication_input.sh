#!/bin/bash
input_file="/home/hadoop/praveen/misshrbt/logs/log.txt"
output_file="/home/hadoop/praveen/misshrbt/inputs/s3uris.txt"
pattern="move: s3://([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+) to s3://ge-power-cust-prod-([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+)"

# open log file for reading
cat "$input_file" | while read line; do
    # check if line contains S3 path information
    if [[ $line == *".parquet"* ]]; then
        # extract information using pattern
        if [[ $line =~ $pattern ]]; then
            cust_zone=${BASH_REMATCH[7]}
            assetid=${BASH_REMATCH[8]}
            year=${BASH_REMATCH[9]}
            month=${BASH_REMATCH[10]}
            day=${BASH_REMATCH[11]}
            prqt=${BASH_REMATCH[12]}
            
            date_stamp="$month/$day/$year"
            
            #s3://ge-power-cust-prod-ba83594d-3c02-4676-9ad8-5336e5830155/assetid=281917/year=2021/month=9/day=17/part-00000-ce3a172c-d2ef-46b1-9474-96a2a529bc19-c000.snappy.parquet
            echo "s3://ge-power-cust-prod-$cust_zone/assetid=$assetid/year=$year/month=$month/day=$day/$prqt" >> $output_file
        fi
    fi
done
