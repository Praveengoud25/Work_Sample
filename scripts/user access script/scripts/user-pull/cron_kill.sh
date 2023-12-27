#!/bin/bash
process=user_access_sync.sh
pid=$(pgrep -f $process )
echo $pid
sleep 30
sudo kill -9 $pid