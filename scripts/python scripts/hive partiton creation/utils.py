import boto3
from datetime import date, datetime, timedelta

from email import encoders
from email.mime.base import MIMEBase
import logging
from datetime import date
import numpy as np
import yaml
from pyspark.sql import SparkSession
import pandas as pd

import smtplib, ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

S3_REGION = "us-west-2"
S3_BUCKET = "usw02-pr-pwr-s3-aurora-timeseries"
S3_FOLDER_PATH = "datastats/summary/daily/"

smtp_server="email-smtp.us-west-2.amazonaws.com"
smtp_port="587"
username="AKIAUHVKNDVGE6CPIT3S"
password="BA9WOrBx44dGx/mwGhhv8J7Vruth1pbFFRYv80s4oVs8"
sender_email = "Smelter.Notifications@ge.com"
sender_name="~DIGITAL Smelter Notification"
receiver_emails=['Kalyana.Kappagantula@ge.com', 'Kalyana.Kappagantula@ge.com']
# CC_email="Hyoung.Jhang@ge.com"


# os.environ['PYSPARK_SUBMIT_ARGS'] = '--packages com.amazonaws:aws-java-sdk-pom:1.10.34,org.apache.hadoop:hadoop-aws:2.7.2 pyspark-shell'

LOG_PATH = "logs/"
logging.basicConfig(filename=LOG_PATH + "/dummy.txt",
                    format='%(asctime)s %(name)s %(levelname)-8s %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    level=logging.INFO)
logger = logging.getLogger()
logger.addHandler(logging.StreamHandler())

def downloadFile(fileName):
    s3_client = boto3.client('s3', verify=False)
    fileFullPath = "%s%s" % (S3_FOLDER_PATH, fileName)
    localFilePath = "./dailyReports/%s" % fileName
    
    s3_client.download_file(Bucket=S3_BUCKET, Key=fileFullPath, Filename=localFilePath)
    print('success')

def update_logger(file_name):
    global logger
    file = open(file_name, 'a+')
    fileh = logging.FileHandler(file_name, 'a')  # a is the append mode
    formatter = logging.Formatter('%(asctime)s %(name)s %(levelname)-8s %(message)s')
    fileh.setFormatter(formatter)
    logger = logging.getLogger()
    for hdlr in logger.handlers[:]:  # remove all old handlers
        logger.removeHandler(hdlr)
    logger.addHandler(fileh)


def get_current_date():
    today = date.today()
    dt = today.strftime("%m_%d_%Y")
    return dt


def load_config(filepath):
    """Load an yaml file"""
    with open(filepath, "r") as file_descriptor:
        yaml_obj = yaml.load(file_descriptor, Loader=yaml.BaseLoader)
    return yaml_obj

def getCustomerZoneID(assetid):
    dfInput = pd.read_csv('./mul/MUL-04192022.csv')
    dfInput = dfInput.astype({"EquipmentSerNum": str, "CustomerZoneId": str, "BlockId": str, "PlantId": str})
    dfquery = pd.DataFrame()
    if assetid[:2].upper() == "BL":
        dfquery = dfInput.loc[dfInput['BlockId'] == assetid]
    elif assetid[:2].upper() == "PL":
        dfquery = dfInput.loc[dfInput['PlantId'] == assetid]
    else:
        dfquery = dfInput.loc[dfInput['EquipmentSerNum'] == assetid]

    if dfquery.shape[0] > 0 :
        for index, dfRow in dfquery.iterrows():
            return dfRow["CustomerZoneId"]
    else:
        return ""

def FetchMULInformation():
    df_Mul = pd.read_csv('./mul/MUL-04192022.csv')
    df_Mul = df_Mul.astype({"EquipmentSerNum": str, "CustomerZoneId": str, "BlockId": str, "PlantId": str})
    df_Mul = df_Mul.rename(columns={'EquipmentSerNum': 'AssetId'}) 
    
    return df_Mul

def FetchAllAssetMetaInformation():
    df_assetMeta = pd.read_csv('./mul/assetmeta-03092022.csv')
    df_assetMeta = df_assetMeta.astype({"ASSET_ID": str, "CUSTOMERZONEID": str})
    df_assetMeta = df_assetMeta.rename(columns={'ASSET_ID': 'AssetId', 'CUSTOMERZONEID': 'CustomerZoneId'}) 
    
    return df_assetMeta


def FetchAssetMetaInformation(assetid):
    df_assetMeta = pd.read_csv('./mul/assetmeta-03092022.csv')
    df_assetMeta = df_assetMeta.astype({"ASSET_ID": str, "CUSTOMERZONEID": str, "OSMNAME": str, "OSMID": str})
    df_assetMeta = df_assetMeta.rename(columns={'ASSET_ID': 'AssetId', 'CUSTOMERZONEID': 'CustomerZoneId'}) 
    df_assetMeta = df_assetMeta.loc[df_assetMeta['AssetId'] == assetid]

    if df_assetMeta.shape[0] > 0 :
        return str(df_assetMeta['CustomerZoneId'].iloc[0])
    else:
        getCustomerZoneID(assetid)

def get_spark_context():
    spark = SparkSession \
        .builder \
        .appName("metric-generator") \
        .enableHiveSupport() \
        .config("spark.executor.memory", "20g") \
        .config("spark.driver.memory", "20g") \
        .config("spark.executor.instances" ,"30") \
        .config("spark.executor.cores" , "4") \
        .config("spark.hadoop.fs.s3.consistent","false") \
        .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", "2") \
        .config("spark.driver.maxResultSize", "0") \
        .config("spark.sql.legacy.timeParserPolicy", "LEGACY") \
        .getOrCreate()
    return spark

def spark_stop(spark):
    spark.stop()

def get_spark_session():
    yml_obj = load_config("./config/config.yaml")
    hive_metastore_uri = yml_obj['hive_metastore_uri']

    s = SparkSession \
        .builder \
        .appName("metric-generator") \
        .config("hive.metastore.uris", hive_metastore_uri) \
        .enableHiveSupport() \
        .getOrCreate()
    return s

def uniqueValueFromList(list1):
    x = np.array(list1)
    unique = np.unique(x)
    print(unique)
    return unique

def getSundayDate(date1):
    # now = datetime.now()
    sunday = date1 - timedelta(days = date1.weekday() + 1)
    print(sunday)

# def sendEmail(outputFileNames, currentDay):
#     message = MIMEMultipart()
#     message["Subject"] = "High volume data report"
#     message["From"] = sender_email
#     message["To"] = ", ".join(receiver_emails)
#     # message["CC"] = CC_email

#     # Create the plain-text and HTML version of your message
#     text = f"""\
#     Hello Team,
#         Attached is the high volume data report for {currentDay} along with top 30 tag wise count for the top 30 high volume assets.

#     Thank you
#     Digtial Team
#     """

#     html = """\
#         <html>
#         <body>
#             <p>Hello Team,<br>

#                 Attached is the high volume data report for """     
#     html = html + currentDay + """ along with top 30 tag wise count for the top 30 high volume assets.<br>

#             </p>
#             <p>Thank you,</p>
#             <p>Digtial Team</p>
#         </body>
#         </html>
#     """

#     # Turn these into plain/html MIMEText objects
#     # part1 = MIMEText(text, "plain")
#     part2 = MIMEText(html, "html")

#     # Add HTML/plain-text parts to MIMEMultipart message
#     # The email client will try to render the last part first
#     # message.attach(part1)
#     message.attach(part2)

#     for outputFileName in outputFileNames:
#         with open(outputFileName, "rb") as attachment:
#             # Add file as application/octet-stream
#             # Email client can usually download this automatically as attachment
#             part = MIMEBase("application", "octet-stream")
#             part.set_payload(attachment.read())
#             attachFileName = ""
#             attachFileName = outputFileName[len('./metricsOutput/'):]

#             part.add_header(
#                 "Content-Disposition",
#                 f"attachment; filename= {attachFileName}",
#             )
#             # Encode file in ASCII characters to send by email    
#             encoders.encode_base64(part)
#             # Add attachment to message and convert message to string
#             message.attach(part)

#     # # Add header as key/value pair to attachment part
#     # part.add_header(
#     #     "Content-Disposition",
#     #     f"attachment; filename= {currentDay}.csv",
#     # )



#     # Create secure connection with server and send email
#     context = ssl.create_default_context()
#     with smtplib.SMTP(smtp_server, smtp_port) as server:
#         server.ehlo()  # Can be omitted
#         server.starttls(context=context)
#         server.ehlo()  # Can be omitted        
#         server.login(username, password)
#         server.sendmail(
#             sender_email, receiver_emails, message.as_string()
#         )

