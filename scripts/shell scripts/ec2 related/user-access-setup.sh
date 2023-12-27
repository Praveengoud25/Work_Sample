#Need to create folders which we save the script
mkdir -p /opt/scripts/user_access_script/

export SSH_KEY_STORE=$1
#s3://ssh-key-btsrp/

export DEFAULT_USER=$2
#ec2-user

export SCRIPTS_DIR_PATH=$3
#/opt/scripts/user_access_script

export CRON_job_DIR_PATH=$4

# Create Cron job and adding permissions to the file
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/user_access_sync.sh" > $CRON_job_DIR_PATH
chmod 006CRON_job_DIR_PATHCRON_job_DIR_PATH $CRON_job_DIR_PATH
chown root:root $CRON_job_DIR_PATH

#Create $SCRIPTS_DIR_PATH/user_access_sync.sh and adding permissions to the file

cat > $SCRIPTS_DIR_PATH/user_access_sync.sh <<EOH
#!/bin/bash
export PATH=$PATH:/usr/local/bin
aws s3 sync s3://$SSH_KEY_STORE/  /home/$DEFAULT_USER/.ssh/ --exact-timestamps
EOH

chmod 00750 $SCRIPTS_DIR_PATH/user_access_sync.sh
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH/user_access_sync.sh

# Calculate the elapsed time
elapsed_time=$(($SECONDS - $start_time))

# Check if the elapsed time exceeds the timeout duration
if [ $elapsed_time -gt $timeout_duration ]; then
  echo "Script timed out after 30 seconds."
  # Add any additional actions you want to perform upon timeout
  exit 1
fi