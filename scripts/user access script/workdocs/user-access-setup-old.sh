#!/bin/bash -xe

# This script is used to sync ssh keys from Bootstrap S3 bucket to the EC2 instance.
# Sample command to run this script
# ./user-access-setup.sh "usw02-dev-pwr-genie" "ec2-user" "/opt/genie" "usw02-dev-pwr-s3-bootstrap" "us-west-2"

export COMPONENT_NAME=$1
export DEFAULT_USER=$2
export SCRIPTS_DIR_PATH=$3/user_access_scripts
export TEMP_SCRIPTS_DIR_PATH=$3/temp_scripts
export S3_BOOTSTRAP_BUCKET=$4
export AWS_REGION=$5

# Create required folders to copy script
mkdir $SCRIPTS_DIR_PATH
mkdir $TEMP_SCRIPTS_DIR_PATH

# Create /etc/cron.d/user_access_sync
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/user_access_sync.sh" > $TEMP_SCRIPTS_DIR_PATH/user_access_sync
install -o root -g root -m 00644 $TEMP_SCRIPTS_DIR_PATH/user_access_sync /etc/cron.d/user_access_sync

# Create $SCRIPTS_DIR_PATH/user_access_sync.sh
cat > $TEMP_SCRIPTS_DIR_PATH/user_access_sync.sh <<EOH
#!/bin/bash
export PATH=$PATH:/usr/local/bin

aws s3 sync s3://$S3_BOOTSTRAP_BUCKET/analytics/user_access/$COMPONENT_NAME/ /home/$DEFAULT_USER/.ssh/ --exact-timestamps --region $AWS_REGION
EOH
install -o $DEFAULT_USER -g $DEFAULT_USER -m 00750 $TEMP_SCRIPTS_DIR_PATH/user_access_sync.sh $SCRIPTS_DIR_PATH/user_access_sync.sh

# Delete temporary folder
rm -rf $TEMP_SCRIPTS_DIR_PATH
# Deleting this script file
rm -rf user-access-setup.sh
