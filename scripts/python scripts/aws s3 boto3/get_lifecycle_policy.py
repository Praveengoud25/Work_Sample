# Module used in python for boto3
import boto3
import json

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='011821064023_mnd-l3-support-role')

#testing the login by getting region name of the above profile
print(session.region_name)

#defined proxy for the flow of data between clients
proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
#defining the services we want using sessions here ver defined s3 session
#s3 = session.resource('s3', verify = False)


s3 = session.client('s3', verify=False)
result = s3.get_bucket_lifecycle (Bucket='ge-power-arf-shim-stage-us-west-2-replication')
#print(result)
json_formatted_str = json.dumps(result)
print(json_formatted_str)