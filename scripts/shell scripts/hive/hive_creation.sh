#!/bin/bash
input_file="/home/hadoop/praveen/misshrbt/logs/log.txt"
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
            if [ ${#month} -eq 1 ]; then
                month="0$month"
            fi
            if [ ${#day} -eq 1 ]; then
                day="0$day"
            fi
            date_stamp="$year$month$day"

	    final_path="${BASH_REMATCH[7]}/assetid=${BASH_REMATCH[8]}/year=${BASH_REMATCH[9]}/month=${BASH_REMATCH[10]}/day=${BASH_REMATCH[11]}/"
            # write information to output file in CSV format
            #echo 
            echo "ALTER TABLE gep_data_v2.assetid_$assetid ADD IF NOT EXISTS PARTITION (customer='$cust_zone',assetid='$assetid',date_stamp='$date_stamp') LOCATION 's3://ge-power-cust-prod-$final_path';"
	    hive -e "ALTER TABLE gep_data_v2.assetid_$assetid ADD IF NOT EXISTS PARTITION (customer='$cust_zone',assetid='$assetid',date_stamp='$date_stamp') LOCATION 's3://ge-power-cust-prod-$final_path';"
        fi
    fi
done
