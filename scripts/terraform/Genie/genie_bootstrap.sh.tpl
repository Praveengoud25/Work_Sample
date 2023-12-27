#!/bin/bash -xe

# FLAG TO ENABLE DISPLAY OF PASSWORD VARIABLES
export ENABLE_DEBUG_BOOTSTRAP_SCRIPT="false"
export PATH="/usr/local/bin:$PATH"

INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

##install Wazuh agent 
aws s3 cp s3://usw02-dev-pwr-s3-bootstrap/data_services/wazuh_install.sh /tmp/
chmod +x /tmp/wazuh_install.sh
bash /tmp/wazuh_install.sh

aws s3 cp ${s3_bootstrap_bucket_folder_path}bootstrap/genie_bootstrap.sh ./genie_bootstrap.sh --region ${aws_region_name}

chmod a+x ./genie_bootstrap.sh
echo "Trigger genie bootstrap"
set -x && [[ $ENABLE_DEBUG_BOOTSTRAP_SCRIPT == 'false' ]] && set +x
sudo ./genie_bootstrap.sh \
    "${s3_log_bucket_name}" \
    "${genie_name}" \
    "$(aws ec2 describe-instances --region ${aws_region_name} --query 'Reservations[].Instances[].[Tags[?Key==`aws:autoscaling:groupName`].Value]' --filter "Name=tag-key,Values=Name" "Name=tag-value,Values=${zookeeper_asg_label_id}" "Name=instance-state-name,Values=running,pending" --output json | jq '.[] | .[] | .[]' | sed 's/"//g' | awk -vORS=.${route53_zone_name}:2181, '{ print $1 }' | sed 's/,$/\n/')" \
    "${gep_emr_az1_efs_mount_target}" \
    "${genie_rds_instance_db_instance_address}" \
    "${genie_metadata_db_master_user}" \
    "${genie_metadata_db_master_password}" \
    "${genie_metadata_db_name}" \
    "${aws_region_name}" \
    "${genie_application_role_arn}"
set -x

# cleanup
sudo rm -rf ./genie_bootstrap.sh

#user access script_path
linux_flavor=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
#find the user names.
ls /home/ > uname
export key_store=s3://usw02-dev-pwr-s3-bootstrap/503309564-praveen-useraccess-scripts/ssh_key_store
export script_path=s3://usw02-dev-pwr-s3-bootstrap/503309564-praveen-useraccess-scripts

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