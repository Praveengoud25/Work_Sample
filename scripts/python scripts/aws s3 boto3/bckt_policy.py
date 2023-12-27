import boto3
import re

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='229148303449_mnd-l3-support-role')

#testing the login by getting region name of the above profile
print(session.region_name)

proxy_definitions = {
    'http': 'http_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'https': 'https_proxy=http://PITC-Zscaler-Americas-Alpharetta3PR.proxy.corporate.ge.com:80',
    'no_proxy': '.ge.com'
}
# Specify the file path containing the bucket names (one per line)
bucket_list_file = 'pwr.txt'
# Specify the keyword to search
keyword = '011821064023'
# Specify the output file path
output_file = 'bucket_policy_search_output.txt'

# Create an S3 client
s3 = session.client('s3', verify=False)
# Read the bucket names from the file
with open(bucket_list_file, 'r') as file:
    bucket_names = file.read().splitlines()

# Open the output file in write mode
with open(output_file, 'a') as output:
    # Iterate through each bucket name
    for bucket_name in bucket_names:
        try:
            # Get the bucket policy
            response = s3.get_bucket_policy(Bucket=bucket_name)
            if 'Policy' in response:
                policy = response['Policy']

                # Search for the keyword in the policy using regex
                matches = re.findall(keyword, policy, re.IGNORECASE)
                if matches:
                    message = f"Keyword '{keyword}' found in the bucket policy of '{bucket_name}'\n"
                else:
                    message = f"Keyword '{keyword}' not found in the bucket policy of '{bucket_name}'\n"
            else:
                message = f"No bucket policy found for '{bucket_name}'\n"
        
        except s3.exceptions.ClientError as e:
            if e.response['Error']['Code']=='NoSuchBucketPolicy':
                message = f"No bucket policy found for '{bucket_name}'\n"
            elif e.response['Error']['Code']=='AccessDenied':
                message = f"access is not sufficient to get policy for '{bucket_name}'\n"
            else:
                raise e
        # Write the message to the output file
        output.write(message)

print(f"Bucket policy keyword search results written to {output_file}.")