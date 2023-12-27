import boto3
session = boto3.Session(profile_name='564772463473/ps/psadmin-dev-fed')
print(session.region_name)
bucket_file = 'pwr.txt'
proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}

s3 = session.client('s3', verify=False)
with open(bucket_file, 'r') as a:
    bucket_name = a.read().splitlines()

result1= ''
for bckt in bucket_name:

    result = s3.get_bucket_acl(Bucket=bckt)
    #print(result)
    owner = result['Owner']
    owner_id = owner['ID']
    owner_display_name = owner['DisplayName']

    result1 = f"Owner details for the bucket '{bucket_name}':\nowner id:{owner_id}\nowner_display_name: {owner_display_name}\n\n"

#    print(f"Owner details for bucket '{bucket_name}':")
#    print(f"Owner id: {owner_id}")
#    print(f"Owner Displayname: {owner_display_name}")
#    print()

buck_rslt = 'buck_rslt.txt'
with open(buck_rslt, 'w') as b:
    b.write(result1)