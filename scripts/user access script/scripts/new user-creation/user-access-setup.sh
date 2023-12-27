#!/bin/bash
export SSH_KEY_STORE=$1
#s3://ssh-key-btsrp/

export DEFAULT_USER=$2
#ec2-user

export SCRIPTS_DIR_PATH=$3
#/opt/scripts/user_access_script

export CRON_job_DIR_PATH=$4

#Need to create folders which we save the script
mkdir -p $3

#Create $SCRIPTS_DIR_PATH/user_access_sync.sh and adding permissions to the file
cat > $SCRIPTS_DIR_PATH/user_access_sync.sh <<EOH
#!/bin/bash
export PATH=$PATH:/usr/local/bin
aws s3 sync s3://$SSH_KEY_STORE/  /home/$DEFAULT_USER/.ssh/ --exact-timestamps
EOH

chmod 00750 $SCRIPTS_DIR_PATH/user_access_sync.sh
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH/user_access_sync.sh


# Create Cron job and adding permissions to the file
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/user_access_sync.sh" > $CRON_job_DIR_PATH
chmod 006  $CRON_job_DIR_PATH
chown root:root $CRON_job_DIR_PATH