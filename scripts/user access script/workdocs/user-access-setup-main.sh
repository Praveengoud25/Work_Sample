#Name of the file user-access-setup.sh

#this scipt is called from user data script
##Export the inputs from user data 

mkdir -p /opt/scripts/user_access_script/

export SSH_KEY_STORE=$1
#s3://ssh-key-btsrp/

export DEFAULT_USER=$2
#ec2-user

export SCRIPTS_DIR_PATH=$3
#/opt/scripts/user_access_script

# Create /etc/cron.d/user_access_sync and adding permissions to the file
echo "*/1 * * * * root $SCRIPTS_DIR_PATH/user_access_sync.sh" > /etc/cron.d/user_access_sync
chmod 00644 /etc/cron.d/user_access_sync
chown root:root /etc/cron.d/user_access_sync

#Create $SCRIPTS_DIR_PATH/user_access_sync.sh and adding permissions to the file

cat > $SCRIPTS_DIR_PATH/user_access_sync.sh <<EOH
#!/bin/bash
export PATH=$PATH:/usr/local/bin
aws s3 sync s3://$SSH_KEY_STORE/  /home/$DEFAULT_USER/.ssh/ --exact-timestamps
EOH

chmod 00750 $SCRIPTS_DIR_PATH/user_access_sync.sh
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH/user_access_sync.sh

rm -rf user-access-setup.sh