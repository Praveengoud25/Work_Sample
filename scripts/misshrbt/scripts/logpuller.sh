#!/bin/bash
input_file="/home/hadoop/praveen/paths.txt"
output_file="/home/hadoop/praveen/input-stream.csv"
pattern="move: s3://([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+) to s3://ge-power-cust-prod-([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+)"
# Creating header to the output file
echo AssetId,StartDate,CustomerZoneId > "$output_file"
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
            if [ ${#month} -eq 1 ]; then
                month="0$month"
            fi
            if [ ${#day} -eq 1 ]; then
                day="0$day"
            fi
            date_stamp="$month/$day/$year"
            # write information to output file in CSV format
            #AssetId,StartDate,CustomerZoneId           
            #BL000556,11/01/2014,08f1e6dc-8154-4f6f-afa7-7b2806f324b9
            echo $assetid,$date_stamp,$cust_zone >> "$output_file"
        fi
    fi
done

