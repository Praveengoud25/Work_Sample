#!/bin/bash
set -ex
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
ACCOUNT_ID='277651853236'
AWS_REGION='us-west-2'
echo $INSTANCE_ID

ALARM_NAME="ClockErrorBound:${ACCOUNT_ID}:af-ba:"
ALARM_NAME+=$(hostname -I | sed -r 's!/.*!!; s!.*\.!!')
ALARM_NAME="$(echo -e "${ALARM_NAME}" | tr -d '[:space:]')"
echo "\"$ALARM_NAME\""

SNS_ARN=arn:aws:sns:${AWS_REGION}:${ACCOUNT_ID}:unhealthy_nodes_cloudwatch_alarm

aws cloudwatch put-metric-alarm \
                                --alarm-name           "${ALARM_NAME}"                                         \
                                --alarm-description    "ClockErrorBound exceeds 10 seconds"                    \
                                --metric-name          ClockErrorBound                                         \
                                --namespace            TimeDrift                                               \
                                --statistic            Average                                                 \
                                --period               60                                                      \
                                --threshold            10000                                                   \
                                --comparison-operator  GreaterThanThreshold                                    \
                                --dimensions           "Name=Instance,Value=${INSTANCE_ID}"                    \
                                --evaluation-periods   1                                                       \
                                --alarm-actions        ${SNS_ARN}                                              \
                                --region               ${AWS_REGION}