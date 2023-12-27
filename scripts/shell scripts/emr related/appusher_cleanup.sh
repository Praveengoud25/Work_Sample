systemctl status apppusher

#adding apppusher script
cat > /emr/apppusher/apppusher_table_cleanup.sh <<EOH
#!/bin/bash
set -eux
sudo rm -rf /emr/apppusher/ytsdata /emr/apppusher/data
sudo systemctl restart apppusher
EOH

chmod +x /emr/apppusher/apppusher_table_cleanup.sh

#Creating cron job.
cron_job="0 0 * * 0 /emr/apppusher/apppusher_table_cleanup.sh > /tmp/apppusher_cleanup_job.log 2>&1"
(crontab -l ; echo "$cron_job") | crontab -