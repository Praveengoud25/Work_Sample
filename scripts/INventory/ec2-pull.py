# Module used in python for boto3
import boto3

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='011821064023_mnd-l3-support-role')

#testing the login by getting region name of the above profile
print(session.region_name)

#defining the services we want using sessions here ver defined s3 session
ec2 = session.client('ec2', verify=False)
for instance in ec2.instances.all():
     print(
         "Id: {0}\nPlatform: {1}\nType: {2}\nPublic IPv4: {3}\nAMI: {4}\nState: {5}\n".format(
         instance.id, instance.platform, instance.instance_type, instance.public_ip_address, instance.image.id, instance.state
         )
     )