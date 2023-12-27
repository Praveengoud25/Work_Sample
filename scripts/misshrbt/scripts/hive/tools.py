# -*- coding: utf-8 -*-
"""
Created on Wed Apr 16 14:28:00 2020

@author: 223024632
"""

import pandas as pd
import logging
import os
import csv

HANDLERS = [logging.FileHandler('./logs/metric-generator.log', 'w'), logging.StreamHandler()]
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(message)s', handlers=HANDLERS)

SCRIPTFOLDER = "./completed"
WHICH_FILES_MERGE = "step8_addpartition.hql"
MERGED_FILENAME = './completed/step8_addpartition-mergered.hql'

filelist = []
mergedDataList = []
pd_megered = pd.DataFrame()

if os.path.exists(SCRIPTFOLDER):
    for root, dirs, files in os.walk(SCRIPTFOLDER):
        for file in files:
            #append the file name to the list
            fileName = os.path.join(root,file)
            filelist.append(fileName)
            print(fileName)

            if WHICH_FILES_MERGE in fileName:
                pd_df = pd.read_csv(fileName, sep='~', header=None, names=['statement'])
                
                if pd_megered.empty:
                    pd_megered = pd_df
                else:
                    pd_megered = pd_megered.merge(pd_df, how='outer')

    mergedFile = pd_megered.to_csv(MERGED_FILENAME, index=0, header=None);
    pd_out = pd_megered.statement.drop_duplicates()
    mergedFile = pd_out.to_csv(MERGED_FILENAME, index=False, header=None);


#print all the file names
# for name in filelist:
#     print(name)

    # subdirs = [f'{x[0]}' for x in os.walk(SCRIPTFOLDER)]
    # print(subdirs)

