#we have bucket list and thier volumes now we have merge the files now
paste buckets.txt vol.csv obj.csv > dev.csv
#
cat dev.csv | awk -F'/' '{print $1 "\t" $3}' 
#
awk 'BEGIN {FS=":" ; OFS=" " } {print $1,$2,$3}' dev.csv >> s3bucketvol.csv