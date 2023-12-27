# Module used in python for boto3
import boto3
import json

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='564772463473/ps/psadmin-dev-fed')

#testing the login by getting region name of the above profile
print(session.region_name)

#defined proxy for the flow of data between clients
proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
#defining the services we want using sessions here ver defined s3 session

s3 = session.client('s3', verify=False)
result = s3.get_bucket_policy (Bucket='ge-power-cust-prod-dl-011d24fb-1fba-4912-87ab-4e8417418bbf')
#print(result)
#json_formatted_str = json.dumps(result)
print(result)