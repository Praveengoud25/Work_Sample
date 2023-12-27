import boto3
import re

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='564772463473/ps/psadmin-dev-fed')

#testing the login by getting region name of the above profile
print(session.region_name)

proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
def search_bucket_policy(bucket_name, keyword):
    # Create an S3 client
    s3 = session.client('s3', verify=False)
    s3_client = boto3.client('s3')

    # Get the bucket policy
    try:
        result = s3.get_bucket_policy (Bucket='ge-power-cust-prod-dl-011d24fb-1fba-4912-87ab-4e8417418bbf')
        policy = result['Policy']

        # Search for the keyword in the policy using regex
        matches = re.findall(keyword, policy, re.IGNORECASE)
        if matches:
            print(f"Keyword '{keyword}' found in the bucket policy of '{bucket_name}'")
        else:
            print(f"Keyword '{keyword}' not found in the bucket policy of '{bucket_name}'")
    except s3_client.exceptions.NoSuchBucketPolicy:
        print(f"No bucket policy found for '{bucket_name}'")

# Specify the bucket name and the keyword to search
bucket_name = 'ge-power-cust-prod-dl-011d24fb-1fba-4912-87ab-4e8417418bbf'
keyword = '867396380247'

# Call the function to search for the keyword in the bucket policy
search_bucket_policy(bucket_name, keyword)
