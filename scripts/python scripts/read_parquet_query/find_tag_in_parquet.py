# This utility method will open parquet file from S3 and inspect a tag
import io
import boto3
import pandas as pd
from botocore.client import Config

PROD_PROFILE = '867396380247_mnd-l3-support-role'
S3_PARQUET_PATH = 's3://ge-power-cust-prod-a4960d7e-fb30-4d05-b30b-b99ccd0cef68/assetid=875100/year=2023/month=8/day=3/'
TAG_NAME = 'TNH'
S3_REGION = 'us-west-2'


def get_s3_session():
    """
    This method returns S3 session
    """

    config = Config(connect_timeout=10,
                    max_pool_connections=10,
                    read_timeout=60,
                    retries={'max_attempts': 0})
    session = boto3.Session(profile_name=PROD_PROFILE)
    s3_client = session.client(service_name='s3', verify=False,
                               region_name=S3_REGION,
                               config=config)
    return s3_client


def get_bucket_and_key(s3_uri):
    """
    This method returns bucket name and rest of the uri (bucket key)
    Example: 's3://delete-me-ashish-mondal/customers/ge-power-cust-prod/part-0000-25927e73-1236-4ba7-9e37-9e0c73cc9d71.snappy.parquet'
    will be broken into delete-me-ashish-mondal AND customers/ge-power-cust-prod/part-0000-25927e73-1236-4ba7-9e37-9e0c73cc9d71.snappy.parquet
    """
    bucket, bucket_key = s3_uri.split('/', 2)[-1].split('/', 1)
    return bucket, bucket_key


def get_data_frame_from_parquet(s3_uri):
    """
    This method creates dataframe from parquet file in S3
    """
    df = pd.DataFrame()
    file_size = 0
    try:
        bucket, bucket_key = get_bucket_and_key(s3_uri)
        response = get_s3_session().list_objects(Bucket=bucket, Prefix=bucket_key)
        final_df = pd.DataFrame()
        for key in response['Contents']:
            print(f"Reading file: {key['Key']}")
            csv_obj = get_s3_session().get_object(Bucket=bucket, Key=key['Key'])
            body = csv_obj['Body']
            file_size += int(csv_obj['ContentLength'])
            # Read those Parquet files do not cross its threshold
            df = pd.read_parquet(io.BytesIO(body.read()))
            print(f'Number of records found: {len(df)}')
            if len(df) > 0:
                df['ingestion_quality'] = df.ingestion_quality.astype('int32')
                df['quality'] = df.quality.astype('int32')
                df['date_time'] = df.date_time.apply(pd.Timestamp)
                df['ingestion_time'] = df.ingestion_time.apply(pd.Timestamp)
                df[['tagname', 'value', 'ingestion_source']] = \
                    df[['tagname', 'value', 'ingestion_source']].astype(pd.StringDtype())

                df_asset = df[df['tagname'] == TAG_NAME]
                if len(df_asset) > 0:
                    print(f"{len(df_asset)} datapoints found in Tag {TAG_NAME} found in file: {key['Key']}")
                final_df = pd.concat([final_df, df], axis=0)
                print(f"Number of records after merge: {len(final_df)}")
    except Exception as e:
        print(f'Failed to read parquet file: {s3_uri} with an exception: {e}')
        file_size = -100
    return final_df, file_size


# df, file_size = get_data_frame_from_parquet(f'{S3_PARQUET_PATH}part-0000-90e700f6-54dc-4fc1-8c73-7ab5e0df6b93.snappy.parquet')
df, file_size = get_data_frame_from_parquet(S3_PARQUET_PATH)
print(f'Total records found: {len(df)} and file size = {file_size}')
# print(df.head().to_csv('/tmp/aa.csv'))
df_asset = df[df['tagname'] == TAG_NAME]
print(f'Number of datapoints for tag: {TAG_NAME}: {len(df_asset)}')

bucket, bucket_key = get_bucket_and_key(S3_PARQUET_PATH)
unique_tags = df["tagname"].unique()
print(f'Number of unique tags: {len(unique_tags)} for the asset-day {bucket_key}')
print(f"Unique tags: {unique_tags}")