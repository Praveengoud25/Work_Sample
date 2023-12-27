import boto3
session = boto3.Session(profile_name='011821064023_mnd-l3-support-role')
print(session.region_name)

proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
bucket = 'usw02-dev-pwr-s3-intermittent-compaction'
subfolder = 'merged-parquet/'
s3 = session.client('s3', verify=False)
response = s3.list_objects_v2(Bucket=bucket, Prefix=subfolder)

for object in response.get['Contents']:
    print(object['key'])
    