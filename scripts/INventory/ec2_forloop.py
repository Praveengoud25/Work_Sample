import boto3

profiles = [
    'ap-southeast-1',
    'us-west-1',
    'us-east-1',
]
#defining a for loop for getting 
for profile in profiles:
    session = boto3.Session(profile_name='profile')
    #testing the login by getting region name of the above profile
    print(session.region_name)

