# Module used in python for boto3
import boto3
import json

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='277651853236_mnd-l3-support-role')

#testing the login by getting region name of the above profile
print(session.region_name)

#defined proxy for the flow of data between clients
proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
s3 = session.client('s3', verify=False)

response = s3.get_bucket_replication(
    Bucket='ge-power-cust-prod-001143c1-015d-4dfc-9dc7-a3ea7ead5999',
)
#print(result)
json_formatted_str = json.dumps(response)
print(json_formatted_str)