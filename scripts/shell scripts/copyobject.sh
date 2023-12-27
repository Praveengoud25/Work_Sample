#!/bin/bash
#created while loop to read 2 variables 1 throttled_path 2 corrected_path 
while read -r throttled_path && read -r corrected_path <&3; do
        echo -e "$throttled_path\n$corrected_path";
#this cmd will copy objects from one bucket to other bucket 
        aws s3 cp s3://503309564-test/$throttled_path s3://503309564-test/$corrected_path
#we need to give the objects path in the files as given names below
done < throttled.txt 3<correctpath.txt
