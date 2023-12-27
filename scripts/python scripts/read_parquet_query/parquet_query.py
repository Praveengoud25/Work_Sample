import os
import sys
import logging
#configuring the logings
log_file = "/var/log/hadoop-yarn/query.log"  
error_log = "/var/log/hadoop-yarn/error.log"
logging.basicConfig(filename=log_file, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logging.basicConfig(filename=error_log, level=logging.ERROR)

SSO = input('Enter your SSO: ')

#Id of the person running the code

logging.info("SSO id of the user is {}...".format(SSO))
print("Your SSO is :", SSO)
#this is used lock the prog and does not allow to run when already running
logging.info("describing the lock file details")
lock_file = "/home/hadoop/read_parquet_query/parqetquery.lock"
#check if lock file exits

if os.path.exists(lock_file):
    print("Caution: the same script is already running.")
    sys.exit(1) # Exit with code error code 1

#creates the lock file
logging.info("creating the lockfile")
open(lock_file, "w").close()
try:
    import configparser
    config = configparser.ConfigParser()
    config.read('config.ini')
    path = config.get('s3', 's3_path')
    suffix = config.get('s3', 'suffix')
    tag_name = config.get('query', 'tagname')
    from_date = config.get('query', 'from_date')
    to_date = config.get('query', 'to_date')
    output_path = "/home/hadoop/read_parquet_query/s3_query.csv"

    import awswrangler as wr
    #df=wr.s3.list_objects(path=s3_path,suffix='.parquet')
    df = wr.s3.list_objects(path=path,suffix=suffix)
    logging.info("listing the objects from the bucket {}...".format(df))
    useHeader= True
    for i in df:
        df3=wr.s3.read_parquet(path=i).query("tagname==@tag_name and date_time.between(@from_date,@to_date) ")
        logging.info("reading the data from the parquet {}...".format(df3))

        if len(df3) > 0:
                print(f"Output written to: {output_path}")
                logging.info('writing the quried data to the {}...'.format(output_path))        
        else:
            with open("/var/log/hadoop-yarn/error.log", "w") as c:
                c.write("No data found for given tag and date details")
            print(f"No data found for given tag and date deatils")

        df3.head(10).to_csv(output_path, sep=',', doublequote=False, index=False, mode="a", header=useHeader)
        useHeader=False
        del df3
except Exception as e:
    print(f"An error occured: {str(e)}")
            # creating/opening a file
    f = open(error_log, "w")

    # writing in the file
    f.write(str(e))

    # closing the file
    f.close()
    sys.exit(1) # Exit with code 1

finally:
    #Remove Lock file
    if os.path.exists(lock_file):
        os.remove(lock_file)
logging.info("the program finished")
