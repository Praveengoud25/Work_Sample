import boto3
session = boto3.Session(profile_name='011821064023_mnd-l3-support-role')#, region_name='us-west-2')
print(session.region_name)

proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
#s3 = session.resource('s3', verify=False)
#ge-power-arf-shim-stage-us-west-2-replication
s3 = session.resource('s3', verify = False)

bytes = sum([object.size for object in s3.Bucket('ge-power-arf-shim-stage-us-west-2').objects.all()])
print(f'total bucket size: {bytes//1000/1024/1024} GB')