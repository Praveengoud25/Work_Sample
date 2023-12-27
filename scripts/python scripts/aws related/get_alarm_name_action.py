import boto3
import re

#creating a session of aws login using profile from aws_crediantials ENV
session = boto3.Session(profile_name='497021971364_mnd-l3-support-role')

#testing the login by getting region name of the above profile
print(session.region_name)

def get_cloudwatch_alarms():
    client = session.client('cloudwatch', verify=False)
    response = client.describe_alarms()

    with open('alarms.txt', 'w') as f:
        for alarm in response['MetricAlarms']:
            alarm_name = alarm['AlarmName']
            alarm_actions = alarm['AlarmActions']

            f.write(f"Alarm name: {alarm_name}\n")
            f.write(f"      Alarm Actions: {alarm_actions}\n\n")
if __name__ == "__main__":
    get_cloudwatch_alarms()