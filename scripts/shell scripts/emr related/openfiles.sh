#!/bin/bash
pgrep -f yarn >> pids.txt
file=pids.txt
for pid in `cat $file`
do
echo "$pid"
sudo lsof -p $pid | wc -l
done
rm $file