#hive -e show partitions gep_data_v2.assetid_296637 partition (assetid='296637',date_stamp='20020201');
#!/bin/bash
source=/home/hadoop/praveen/misshrbt/scripts/move_s3.sh
cat $log_file
#input_file="/home/hadoop/praveen/misshrbt/logs/log.txt"
pattern="copy: s3://([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+) to s3://ge-power-cust-prod-([a-zA-Z0-9_-]+)/assetid=([a-zA-Z0-9_-]+)/year=([0-9]+)/month=([0-9]+)/day=([0-9]+)/([a-zA-Z0-9._-]+)"

# open log file for reading
cat "$input_file" | while read line; do
    # check if line contains S3 path information
    if [[ $line == *".parquet"* ]]; then
        # extract information using pattern
        if [[ $line =~ $pattern ]]; then
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
            
            hive -e "show partitions gep_data_v2.assetid_$assetid partition (assetid='$assetid',date_stamp='$date_stamp');"
        
        fi
    fi
done            