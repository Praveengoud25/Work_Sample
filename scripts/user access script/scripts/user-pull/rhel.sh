#!/bin/bash
echo $name
sudo yum install cronie -y
echo $script_path
aws s3 cp $script_path/generic-user-ssh-access.sh ./generic-user-ssh-access.sh
chmod a+x ./generic-user-ssh-access.sh
sudo ./generic-user-ssh-access.sh \
    "$key_store" \
    "$name" \
    "/opt/scripts/user_access_script" \
    "/etc/cron.d/" \
    "us-west-2" \
    "$script_path"
sudo systemctl restart crond
sudo service crond restart
rm -rf generic-user-ssh-access.sh