#!/bin/bash
SCRIPTS_DIR_PATH=/opt/scripts/user_access_script/cron_kill.sh
CRON_job_DIR_PATH=/etc/cron.d/user_access_monitor
export DEFAULT_USER=$1
#Writting cronjob kill shell script file
cat > $SCRIPTS_DIR_PATH <<EOH
#!/bin/bash
process=user_access_sync.sh
pid=$(pgrep -f $process )
echo $pid
sleep 30
sudo kill -9 $pid
EOH

#adding permmisions 
chmod 00750 $SCRIPTS_DIR_PATH
chown $DEFAULT_USER:$DEFAULT_USER $SCRIPTS_DIR_PATH

# Creating cron job 
echo "*/1 * * * * root $SCRIPTS_DIR_PATH" > $CRON_job_DIR_PATH