#!/bin/bash
export SSH_KEY_STORE=$1
#s3://ssh-key-btsrp/

export DEFAULT_USER=$2
#ec2-user

export SCRIPTS_DIR_PATH=$3
#/opt/scripts/user_access_script

export CRON_job_DIR_PATH=$4

export aws_path=$6
#Need to create folders where we save the script
mkdir -p $3

#Create $SCRIPTS_DIR_PATH/user_access_sync.sh and adding permissions to the file
cat > $SCRIPTS_DIR_PATH/user_access_sync.sh <<EOH
#!/bin/bash
export PATH=$PATH:/usr/local/bin
aws s3 sync $SSH_KEY_STORE  /home/$DEFAULT_USER/.ssh/ --exact-timestamps
EOH

chmod 00750 $SCRIPTS_DIR_PATH/user_access_sync.sh
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH/user_access_sync.sh

# Create Cron job and adding permissions to the file
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/user_access_sync.sh" > $CRON_job_DIR_PATH/user_access_sync
chmod 00644  $CRON_job_DIR_PATH/user_access_sync
chown root:root $CRON_job_DIR_PATH/user_access_sync

#This script is to kill the user access script if runs more then 30 sec's 
aws s3 cp $aws_path/cron_kill.sh $SCRIPTS_DIR_PATH/cron_kill.sh
chmod +x $SCRIPTS_DIR_PATH/cron_kill.sh
#adding permisions to the script
chmod 00750 $SCRIPTS_DIR_PATH/cron_kill.sh
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH/cron_kill.sh

#Creating cron job for the script to run every one min
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/cron_kill.sh" > $CRON_job_DIR_PATH/cron_monitor
chmod 00644  $CRON_job_DIR_PATH/cron_monitor
chown root:root $CRON_job_DIR_PATH/cron_monitor
