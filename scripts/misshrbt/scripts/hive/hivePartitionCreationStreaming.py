# -*- coding: utf-8 -*-

import pandas as pd
import logging
from pyspark.sql import SparkSession
from datetime import datetime
import time
import os
#import utils

log_format = "%(asctime)s::%(levelname)s::%(name)s::"\
             "%(filename)s::%(lineno)d::%(message)s"

logfileName = '/home/hadoop/praveen/hive_creation.log'.format(datetime.now())
logging.basicConfig(filename=logfileName, filemode='a', level=logging.INFO, format=log_format)

S3_OSM_BUCKET_PREFIX = "ge-power-cust-prod"

def get_spark_context():
    spark = SparkSession \
        .builder \
        .appName("hive-partition-Streaming-creator") \
        .enableHiveSupport() \
        .config("spark.executor.memory", "20g") \
        .config("spark.driver.memory", "20g") \
        .config("spark.executor.instances" ,"30") \
        .config("spark.executor.cores" , "8") \
        .config("spark.hadoop.fs.s3.consistent","false") \
        .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2") \
        .config("spark.driver.maxResultSize", "0") \
        .config("spark.sql.legacy.timeParserPolicy", "LEGACY") \
        .getOrCreate()
    return spark


def spark_stop(spark):
    spark.stop()


def AddORModifyHivePartition(spark, df):
    row = df.iloc[0]
    try:
        if row[0] == "AssetId":
            pass
        else:
            assetid = str(row[0])
            partitionDate = datetime.strptime(row[1], "%m/%d/%Y")
            ftpartitionDate = datetime.strftime(partitionDate, "%Y%m%d")
            year = int(datetime.strftime(partitionDate, "%Y"))
            month = int(datetime.strftime(partitionDate, "%m"))
            day = int(datetime.strftime(partitionDate, "%d"))
            customerZoneId = ""

            try:
                customerZoneId = str(row[2])
            except:
                customerZoneId = utils.FetchAssetMetaInformation(assetid=assetid)
            

            s3Location = "s3://%s-%s/assetid=%s/year=%s/month=%s/day=%s" % (S3_OSM_BUCKET_PREFIX, customerZoneId, assetid, year, month, day);

            logging.info("Creating Partition for Streaming assetday %s-%s " % (assetid, ftpartitionDate))

            strQuery = "ALTER TABLE gep_data_v2.assetid_%s ADD IF NOT EXISTS PARTITION (customer='%s',assetid='%s',date_stamp='%s') LOCATION '%s'" \
                % (assetid, customerZoneId, assetid, ftpartitionDate, s3Location)

            logging.info(strQuery)
            spark.sql(strQuery)

    except Exception as e:
        logging.info(e)

    return "Created"

class hivePartitionCreationStreaming:
            
    def StartProcessing(self ):
        print(': Process Initiated')
        inputFilePath = "/home/hadoop/praveen/input-stream.csv"
        
        csv_reader = pd.read_csv(inputFilePath, delimiter=',', header=0, chunksize=1)

        rowdata = []
        spark = get_spark_context()
        for df in csv_reader:
            AddORModifyHivePartition(spark, df)
        
        spark_stop(spark)
        logging.info("Returned Data is - %s" % rowdata)

if __name__ == '__main__':
    start = time.time()
    logging.info("Process Started on : %s" % start)
    metricGenerator = hivePartitionCreationStreaming()    
    metricGenerator.StartProcessing()
    end = time.time()
    logging.info("Process Ended on : %s" % end)
    logging.info("Time Taken for the Process to complete on : %s" % (end - start))
