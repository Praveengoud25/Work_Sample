#!/bin/bash

#!/usr/bin/env python3.7

du
cd /home/hadoop/praveen

echo $PATH
export SPARK_HOME=/usr/lib/spark
export PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-src.zip:$PYTHONPATH
export PATH=$SPARK_HOME/bin:$SPARK_HOME/python:$PATH

echo $PATH
echo $PYTHONPATH

python3.7 --version

echo "Starting the process"
python3.7 hivePartitionCreationStreaming.py
echo "Completed the process"

date
