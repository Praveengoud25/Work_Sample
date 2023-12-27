# -*- coding: utf-8 -*-
"""
Created on Wed Apr 16 14:28:00 2020

@author: 223024632
this application has to run for only ASSETDAYS BEFORE November 06th 2021 i.e. before Go-Live
"""

import logging
from datetime import datetime
import time

# importing required library
# import mysql.connector
import pandas as pd
import subprocess

log_format = "%(asctime)s::%(levelname)s::%(name)s::"\
             "%(filename)s::%(lineno)d::%(message)s"

logfileName = './logs/duplicateData-{:%Y-%m-%d}.log'.format(datetime.now())
logging.basicConfig(filename=logfileName, filemode='a', level=logging.INFO, format=log_format)


class GetHivePartitionList:

    # def GetHivePartions(self, dataStamp_Array):
    #     # selecting query
    #     query = f"select TBLS.TBL_NAME, PARTITIONS.PART_NAME, SDS.LOCATION from SDS,TBLS,PARTITIONS where PARTITIONS.SD_ID = SDS.SD_ID "\
    #         f"and TBLS.TBL_ID=PARTITIONS.TBL_ID and TBLS.TBL_NAME like 'assetid_%' AND (PARTITIONS.PART_NAME like '{dataStamp_Array[0]}' or "\
    #         f" PARTITIONS.PART_NAME like '{dataStamp_Array[1]}' or PARTITIONS.PART_NAME like '{dataStamp_Array[2]}' or " \
    #         f" PARTITIONS.PART_NAME like '{dataStamp_Array[3]}' or PARTITIONS.PART_NAME like '{dataStamp_Array[4]}' or " \
    #         f" PARTITIONS.PART_NAME like '{dataStamp_Array[5]}')" 

    #     print(query)        

    #     # connecting to the database
    #     dataBase = mysql.connector.connect(
    #                         host = "pr-emrtshistorical-latest.c2lok6xwg129.us-west-2.rds.amazonaws.com",
    #                         port = 3306,
    #                         user = "premrtshistoricallap",
    #                         passwd = "ivoINvSp78YAjBKZ",
    #                         database = "mysqlmaster" )

    #     df_result = pd.read_sql(query, dataBase)

    #     dataBase.close()
    #     return df_result
                
    def StartProcessing(self ):
        yearList = ['2002', '2003', '2004', '2005', '2006', '2007', '2008', '2009', '2010', '2011', '2012', '2013', '2014', '2015', '2016', '2017', '2018', '2019', '2020', '2021', '2022', '2023']
        
        for whichYear in yearList:
            logging.info(f"Fetching the Hive partitions for the 1st half of year {whichYear}")
            dataStamp_H1_Array = [f"%date_stamp={whichYear}01%", f"%date_stamp={whichYear}02%", f"%date_stamp={whichYear}03%", f"%date_stamp={whichYear}04%", f"%date_stamp={whichYear}05%", f"%date_stamp={whichYear}06%"]
            self.GetHivePartionsFromSubProcess(whichYear=whichYear, dateStamp_Array=dataStamp_H1_Array, whichHalf='H1')
            
            logging.info(f"Fetching the Hive partitions for the 2nd half of year {whichYear}")
            dataStamp_H2_Array = [f"%date_stamp={whichYear}07%", f"%date_stamp={whichYear}08%", f"%date_stamp={whichYear}09%", f"%date_stamp={whichYear}10%", f"%date_stamp={whichYear}11%", f"%date_stamp={whichYear}12%"]
            self.GetHivePartionsFromSubProcess(whichYear=whichYear, dateStamp_Array=dataStamp_H2_Array, whichHalf='H2')

            logging.info(f"Completed fetching the Hive partitions for the year {whichYear}")
        return "Completed"


    def GetHivePartionsFromSubProcess(self, whichYear, dateStamp_Array, whichHalf):
        
        subProcesscmd = f"--execute=select TBLS.TBL_NAME, PARTITIONS.PART_NAME, SDS.LOCATION from SDS,TBLS,PARTITIONS where PARTITIONS.SD_ID = SDS.SD_ID "\
            f" and TBLS.TBL_ID=PARTITIONS.TBL_ID and TBLS.TBL_NAME like 'assetid_%' AND (PARTITIONS.PART_NAME like '{dateStamp_Array[0]}' or "\
            f" PARTITIONS.PART_NAME like '{dateStamp_Array[1]}' or PARTITIONS.PART_NAME like '{dateStamp_Array[2]}' or " \
            f" PARTITIONS.PART_NAME like '{dateStamp_Array[3]}' or PARTITIONS.PART_NAME like '{dateStamp_Array[4]}' or " \
            f" PARTITIONS.PART_NAME like '{dateStamp_Array[5]}')"
        
        
        # subProcesscmd = f'--execute=select * from SDS limit 10'
                
        fileName= f"./hivesPartionsList/{whichYear}-{whichHalf}-hivepartions.tsv"
        
        # logging.info(f"{subProcesscmd}")

        try:
            result_cp = subprocess.check_output(['mysql', '--host=pr-emrtshistorical-latest.c2lok6xwg129.us-west-2.rds.amazonaws.com', 
                '--port=3306', '--database=premrtshistoricallap', '--user=mysqlmaster', '--password=ivoINvSp78YAjBKZ', subProcesscmd])

            # print(result_cp)

            strResult = result_cp.decode("utf-8")

            filewgr = open(f'{fileName}', 'w')
            filewgr.writelines(strResult)

        except Exception as e:
            print('Error while getting executing mysql statement '+ str(e))

        return
        

if __name__ == '__main__':
    start = time.time()
    logging.info("Process Started on : %s" % start)
    getHivePartitionList = GetHivePartitionList()    
    getHivePartitionList.StartProcessing()

    end = time.time()
    logging.info("Process Ended on : %s" % end)
    logging.info("Time Taken for the Process to complete on : %s" % (end - start))
