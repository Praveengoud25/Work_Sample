#!/bin/bash
linux_flavor=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
#find the user names.
ls /home/ > uname
export key_store=s3://usw02-stg-mnd-s3-bootstrap/user_access/authorizekeys_store/
export script_path=s3://usw02-stg-mnd-s3-bootstrap/user_access/

#search for user hadoop
if grep -q hadoop uname
then
    default_username="hadoop"
    aws s3 cp $script_path/rhel.sh .
    chmod +x ./rhel.sh
    export name=$default_username
    ./rhel.sh
#if the above condition is not satisfied it
elif [ "$linux_flavor" == "Amazon Linux AMI" ]; then
    default_username="ec2-user"
    aws s3 cp $script_path/rhel.sh .
    chmod +x ./rhel.sh
    export name=$default_username
    ./rhel.sh

else [ "$linux_flavor" == "Ubuntu" ];
    default_username="ubuntu"
    sudo snap install aws-cli --classic
    aws s3 cp $script_path/ubuntu.sh .
    chmod +x ./ubuntu.sh
    export name=$default_username
    ./ubuntu.sh
fi