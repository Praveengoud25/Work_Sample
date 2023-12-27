#!/usr/bin/env bash
# Script consolidates bootstrap_actions for EMR

# set -x

#Constants
LOGFILE="${HOME}/bootstrap_emr.log"  # Can not use /var/log without sudo every time because this runs as user 'hadoop'
CLOUDWATCH_AGENT_CTL="/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl"
CLOUDWATCH_CONFIG_FILE="/opt/aws/amazon-cloudwatch-agent/bin/config.json"

function displayUsage() {
    local -r scriptName="$(basename "${BASH_SOURCE[0]}")"
    echo -e "\033[1;32m"
    echo    "USE CASES :"
    echo    "    GE Power EMR bootstrap script"
    echo -e "\033[1;34m"
    echo    "DESCRIPTION :"
    echo    "    Parameter                         Description"
    echo    "    --help                            Help page"
    echo    "    --efs-dns '<<id>>'                Mount given EFS (requires --efs-mount)"
    echo    "    --efs-mount '<<mount_point>>'     Mount EFS at given location (requires --efs-dns)"
    echo    "    --emrfs-sync                      Emrfs delete / create"
    echo    "    --no-install-sec-updates          Don't install security related updates (not recommended)"
    echo    "    --install-boto                    Install latest boto3"
    echo    "    --debug                           Debug logging"
    echo -e "\033[1;36m"
    echo    "EXAMPLES :"
    echo    "    ./${scriptName} --help"
    echo    "    ./${scriptName} \\"
    echo    "        --efs-dns 'default' \\"
    echo    "        --efs-mount '/predix' \\"
    echo    "        --install-boto \\"
    echo    "    ./${scriptName} \\"
    echo    "        --install-boto \\"
    echo -e "\033[0m"
    exit "${1}"
}

function logging() {
    local -r message="${1}"
    local -r log_type="${2}"
    if [[ "${log_type}" = "ERROR" ]];then
        echo -e "\033[1;31mERROR: ${message}\033[0m" | tee -a ${LOGFILE}
    elif [[ "${log_type}" = "FATAL" ]];then
        echo -e "\033[1;31mFATAL: ${message}\033[0m" | tee -a ${LOGFILE}
    elif [[ "${log_type}" = "DEBUG" ]];then
        if [[ "${DEBUG}" = "True" ]];then
            echo -e "\033[1;33mDEBUG: ${message}\033[0m" | tee -a ${LOGFILE}
        fi
    elif [[ "${log_type}" = "INFO" ]];then
        echo -e "\033[1;35mINFO: ${message}\033[0m" | tee -a ${LOGFILE}
    fi
}


function main() {
    if [[ "${#}" -lt '1' ]];then
        displayUsage 0
    fi

    # /bin/env >> ~/hadoop_env

    HD_HOME=/home/hadoop
    INSTALL_BOTO="False"
    INSTALL_SECURITY="True"

    OPTS=`getopt -o a:A:B:L:d:g:m:nSbDh --long analytics-dependencies-bucket:,analytics-bucket:,logs-bucket:,genie-endpoint:,bootstrap-bucket:,efs-dns:,efs-mount:,emrfs-sync,no-install-sec-updates,install-boto,debug,help \
                 -n 'bootstrap_emr.sh' -- "$@"`
    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

    # Note the quotes around `$OPTS': they are essential!
    eval set -- "$OPTS"

    while true; do
      case "$1" in
        -b | --install-boto ) INSTALL_BOTO="True"; shift ;;
        -d | --efs-dns ) EFS_DNS="$2"; shift 2 ;;
        -m | --efs-mount ) EFS_MOUNT="$2"; shift 2 ;;
        -n | --emrfs-sync ) EMRFS_SYNC="True"; shift ;;
        -B | --bootstrap-bucket ) BOOTSTRAP_BUCKET="$2"; shift 2 ;;
        -a | --analytics-dependencies-bucket ) ANALYTICS_DEPENDENCIES_BUCKET="$2"; shift 2 ;;
        -A | --analytics-bucket ) ANALYTICS_BUCKET="$2"; shift 2 ;;
        -L | --logs-bucket ) LOGS_BUCKET="$2"; shift 2 ;;
        -g | --genie-endpoint ) GENIE_ENDPOINT="$2"; shift 2 ;;
        -S | --no-install-sec-updates ) INSTALL_SECURITY="False"; shift ;;
        -D | --debug ) DEBUG=true; shift ;;
        -h | --help ) displayUsage 0; shift ;;
        -- ) shift; break ;;
        * ) displayUsage 1; break ;;
      esac
    done

    # Upgrade pip start
    ## EMR Release 5.5.0 has pip version 6.0 which is not compatible with our scripts
    RELEASE_LABEL_CHECK=$(jq -r '.releaseLabel' /mnt/var/lib/info/extraInstanceData.json)
    if [ "${RELEASE_LABEL_CHECK}" == "emr-5.5.0" ]
    then
        # Ref https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install-linux.html
        sudo su
        sudo pip install --upgrade pip==9.0.1
        echo "export PATH=/usr/local/bin:$PATH" >> ~/.bashrc
        source ~/.bashrc
    fi

    sudo yum -y erase 'ntp*'
    sudo yum -y install chrony
    sudo service chronyd start
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y gcc ruby-devel libxml2 libxml2-devel libxslt libxslt-devel libffi-devel openssl-devel postgresql-devel
    sudo pip install lxml --upgrade
    sudo pip install -jxmlease --upgrade
    sudo pip install pika --upgrade
    sudo pip install psycopg2 --upgrade
    sudo pip install pandas --upgrade

    echo "start analytic_services bootstrap_emr.sh">>/tmp/boot_strap_ex_info.txt
    echo $EFS_DNS>>/tmp/boot_strap_ex_info.txt
    echo $EFS_MOUNT>>/tmp/boot_strap_ex_info.txt
    echo $EMRFS_SYNC>>/tmp/boot_strap_ex_info.txt
    echo $BOOTSTRAP_BUCKET>>/tmp/boot_strap_ex_info.txt
    echo $ANALYTICS_DEPENDENCIES_BUCKET>>/tmp/boot_strap_ex_info.txt
    echo $ANALYTICS_BUCKET>>/tmp/boot_strap_ex_info.txt
    echo $LOGS_BUCKET>>/tmp/boot_strap_ex_info.txt
    echo $GENIE_ENDPOINT>>/tmp/boot_strap_ex_info.txt
    echo $INSTALL_SECURITY>>/tmp/boot_strap_ex_info.txt
    echo "stop analytic_services bootstrap_emr.sh">>/tmp/boot_strap_ex_info.txt

    local LOG4J_PATCH="patch-log4j-emr-5.13.1-v1.sh"
    aws s3 cp s3://$BOOTSTRAP_BUCKET/analytics/emr/patches/${LOG4J_PATCH} /tmp/${LOG4J_PATCH} && chmod +x /tmp/${LOG4J_PATCH}
    bash /tmp/${LOG4J_PATCH}

    if [[ $? = 0 ]];then
        echo "log4j success">>/tmp/boot_strap_ex_info.txt
    else
        echo "log4j failure">>/tmp/boot_strap_ex_info.txt
    fi

    # Get Cloudwatch Ubuntu logging package
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    # Install Cloudwatch
    sudo rpm -U ./amazon-cloudwatch-agent.rpm
    # 'expect' module is needed to check if the aws logs service started successfully or not
    sudo yum install -y expect

    #Check inputs
    if [[ "${EFS_DNS}" != "" && "${EFS_MOUNT}" = "" ]];then
        logging 'efs details not provided.' 'FATAL'
        logging "both '--efs-dns' and '--efs-mount' are required." "FATAL"
        displayUsage 1
    fi

    #Run installs
    #sudo yum update-minimal --security -y
    if [[ "${INSTALL_SECURITY}" = "True" ]];then
        logging 'Attempting to install security updates...' 'INFO'
        sudo yum update-minimal --security -y | sudo tee -a "${LOGFILE}"
        if [[ $? = 0 ]];then
            logging 'Success' 'DEBUG'
        else
            logging "Failed to install security updates with command:" "FATAL"
            logging "    sudo yum update-minimal --security -y" "FATAL"
            exit 1
        fi
    fi

    if [[ "${INSTALL_BOTO}" = "True" ]];then
        logging 'Attempting to install boto3...' 'INFO'
        # We include the --upgrade in case its already installed it will be upgraded
        sudo pip install --upgrade boto3==1.9.155 | sudo tee -a "${LOGFILE}"
        sudo pip install --upgrade botocore==1.12.155 | sudo tee -a "${LOGFILE}"
        sudo pip install --upgrade pandas | sudo tee -a "${LOGFILE}"
        if [[ $? = 0 ]];then
            logging 'Success' 'DEBUG'
        else
            logging "Failed to install boto3 with command:" "FATAL"
            logging "    sudo pip install boto3" "FATAL"
            exit 1
        fi
    fi

    
    # < --- Install Dynatrace EMR ------------------------- >
    mkdir -p /tmp/install-dynatrace/ 
    cd /tmp/install-dynatrace/
    aws s3 cp s3://$BOOTSTRAP_BUCKET/analytics/dynatrace/install-dynatrace.sh /tmp/install-dynatrace/install-dynatrace.sh

    bash install-dynatrace.sh emr
    cd /tmp
    rm -rf /tmp/install-dynatrace
    # < --- Install Dynatrace EMR ------------------------- >

    aws s3 cp s3://$BOOTSTRAP_BUCKET/analytics/emr/add_step.sh /tmp/add_step.sh && chmod +x /tmp/add_step.sh

    mkdir /tmp/spark_events
    sudo chown hdfs:hadoop /tmp/spark_events

    echo "Registering Cluster">>/tmp/boot_strap_ex_info.txt
    echo $GENIE_ENDPOINT>>/tmp/boot_strap_ex_info.txt
    echo $BOOTSTRAP_BUCKET>>/tmp/boot_strap_ex_info.txt
    echo $ANALYTICS_DEPENDENCIES_BUCKET>>/tmp/boot_strap_ex_info.txt

    if [[ ! -z $GENIE_ENDPOINT ]]; then
        echo "Cluster Cluster">>/tmp/boot_strap_ex_info.txt
        logging "Initiating registration steps for Genie" "INFO"
        /tmp/add_step.sh s3://$BOOTSTRAP_BUCKET/analytics/genie/scripts/genie_register_cluster.sh,https://$GENIE_ENDPOINT,$ANALYTICS_DEPENDENCIES_BUCKET
    fi

    if [[ ! -z $EMRFS_SYNC ]]; then
        logging "Setting up emrfs sync" 'INFO'
        sync_script=sync_data_buckets.sh
        WAIT_TIME=5
        aws s3 cp s3://$BOOTSTRAP_BUCKET/analytics/emr/$sync_script $HD_HOME
        echo "/bin/bash $HD_HOME/$sync_script" | at now + $WAIT_TIME min
    fi

    # Mount EFS
    if [[ "${EFS_DNS}" != "" && "${EFS_MOUNT}" != "" ]];then
        if [[ ! -d "${EFS_MOUNT}" ]];then
            logging 'EFS mount point does not exist, attempting to create it...' 'INFO'
            sudo mkdir -p "${EFS_MOUNT}"
            if [[ $? = 0 ]];then
                logging 'Success' 'DEBUG'
            else
                logging "Failed to create EFS mount point with command:" "FATAL"
                logging "    sudo mkdir -p \"${EFS_MOUNT}\"" "FATAL"
                exit 1
            fi
        fi
        if [[ `ls -ald "${EFS_MOUNT}"|awk '{print $3 " " $4}'` != "hadoop hadoop" ]];then
            logging 'EFS mount point is not owned by hadoop user, attempting to change permissions...' 'INFO'
            sudo chown hadoop:hadoop "${EFS_MOUNT}"
            if [[ $? = 0 ]];then
                logging 'Success' 'DEBUG'
            else
                logging "Failed to change permissions on EFS mount point with command:" "FATAL"
                logging "    sudo chown hadoop:hadoop \"${EFS_MOUNT}\"" "FATAL"
                exit 1
            fi
        fi
        logging 'Attempting to mount EFS...' 'INFO'
        sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \
            "${EFS_DNS}:/" "${EFS_MOUNT}"
        if [[ $? = 0 ]];then
            logging 'Success' 'DEBUG'
        else
            logging "Failed to mount EFS drive with command:" "FATAL"
            logging "    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 \"${EFS_DNS}:/\" \"${EFS_MOUNT}\"" "FATAL"
            exit 1
        fi
        ##adding efs mount to /etc/fstab
        if grep -q ${EFS_DNS} /etc/fstab
        then
            echo "EFS mount already found in /etc/fstab" > ${HOME}/bootstrap_emr.log
        else
            echo "Adding EFS mount to /etc/fstab" > ${HOME}/bootstrap_emr.log
            echo "${EFS_DNS}:/  /${EFS_MOUNT}  nfs4 defaults,_netdev 0 0" >> /etc/fstab
        fi
    fi

    ## add Cron job to clean up logs
    IS_MASTER=$(jq -r '.isMaster' /mnt/var/lib/info/instance.json)

    if [ "${IS_MASTER}" == "true" ]
    then
        echo "Adding cleanup script to Master"
        cat > /home/hadoop/cleanup.sh <<EOF
#!/usr/bin/env bash
export HADOOP_CLIENT_OPTS="-Xmx6g"
for x in \`hdfs dfs -ls /var/log/spark/apps/ | awk '!/inprogress/{print \$8}'\`; do
echo Deleting \$x
hdfs dfs -rm \$x;
done
EOF

#        chmod +x /home/hadoop/cleanup.sh
#
#        croncmd="/home/hadoop/cleanup.sh"
#        cronjob="*/30 * * * *  $croncmd"
#        ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -

        if [[ ! -z $LOGS_BUCKET ]]; then
            echo "Adding cloudwatch s3 to local sync script to Master"
            cat > /home/hadoop/aero_rta_log_sync.sh <<EOF
#!/usr/bin/env bash
aws s3 sync s3://${LOGS_BUCKET}/aero_rta_cloudwatch/ /home/hadoop/logs/aero_rta_cloudwatch/ --exact-timestamps --region us-west-2 --delete
EOF
            chmod +x /home/hadoop/aero_rta_log_sync.sh

            croncmd="/home/hadoop/aero_rta_log_sync.sh"
            cronjob="*/7 * * * *  $croncmd"
            ( crontab -l | grep -v -F "$croncmd" ; echo "$cronjob" ) | crontab -


            sudo bash -c "cat > ${CLOUDWATCH_CONFIG_FILE} <<EOF
{
    \"agent\": {
        \"run_as_user\": \"root\"
    },
    \"logs\": {
        \"logs_collected\": {
            \"files\": {
                \"collect_list\": [
                    {
                        \"file_path\"       : \"/home/hadoop/logs/aero_rta_cloudwatch/**.log\",
                        \"log_group_name\"  : \"/aero_rta/metrics\",
                        \"log_stream_name\" : \"AeroRtaMetrics\"
                    }
                ]
            }
        }
    }
}
EOF"
        fi
    fi

    if [ "${IS_MASTER}" == "false" ]
    then
        sudo bash -c "cat > ${CLOUDWATCH_CONFIG_FILE}  <<EOF
{
    \"agent\": {
        \"run_as_user\": \"root\"
    },
    \"logs\": {
        \"logs_collected\": {
            \"files\": {
                \"collect_list\": [
                    {
                        \"file_path\"       : \"/var/log/hadoop-yarn/containers/*/*/analytics_metrics\",
                        \"log_group_name\"  : \"/analytics/metrics\",
                        \"log_stream_name\" : \"AnalyticsMetrics\"
                    },
                    {
                        \"file_path\"       : \"/var/log/hadoop-yarn/containers/*/*/streaming_analytic_metrics\",
                        \"log_group_name\"  : \"/streaming/metrics\",
                        \"log_stream_name\" : \"StreamingAnalyticMetrics\"
                    }
                ]
            }
        }
    }
}
EOF"

    fi

    #start Cloudwatch
    sudo $CLOUDWATCH_AGENT_CTL -a fetch-config -m ec2 -c file:$CLOUDWATCH_CONFIG_FILE -s

    # The following status check will exit with code 1 if no match is found within 15 seconds
    # (specified by the TIMEOUT variable), or exit with code 0 if a match is found.
    # The substring to look for is expected to be passed in as the first argument to the script.
    TIMEOUT=15
    SUBSTRING='running'
    COMMAND="sudo $CLOUDWATCH_AGENT_CTL -a status"
    sleep 5
    expect -c "set echo \"-noecho\"; set timeout $TIMEOUT; spawn -noecho $COMMAND; expect timeout { exit 1 } eof { exit 2 }"
    TIMEOUT_EXIT_CODE=$?
    if [ $TIMEOUT_EXIT_CODE == 1 ]; then
        echo "Did not find '$SUBSTRING' in $TIMEOUT seconds for the command $COMMAND."
        exit 1
    elif [ $TIMEOUT_EXIT_CODE == 2 ]; then
        echo "AWS Logs successfully started..."
    fi


    # Add Splunk Forwarder installation    
    if [ "${IS_MASTER}" == "false" ]
    then
        export SPLUNK_HOME=/opt/splunkforwarder
        # set forwarder to use
        export SPLUNK_FORWARDER_SERVER="fwd.usw02.log.predixtelemetry.com:9997"

        cd /tmp

        # download SplunkUniversalForwarder package
        sudo wget -O splunkforwarder-8.0.5-a1a6394cc5ae-linux-2.6-x86_64.rpm 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.5&product=universalforwarder&filename=splunkforwarder-8.0.5-a1a6394cc5ae-linux-2.6-x86_64.rpm&wget=true'

        # install SplunkUniversalForwarder package
        sudo rpm -i splunkforwarder-8.0.5-a1a6394cc5ae-linux-2.6-x86_64.rpm

        # Remove SplunkUniversalForwarder package
        sudo rm -rf splunkforwarder-8.0.5-a1a6394cc5ae-linux-2.6-x86_64.rpm

        sudo mkdir -p ${SPLUNK_HOME}/etc/system/local/

        # HASHED PWD - $6$pMJ0oz6BPTB6vt6I$eYStL/reA89frAKdlizTPdbp4A6TgsKLA23hBIjwWc5C0.0DbSzjn/07SrBRIYKOY.6t/.nxY2Um3VqImC8AB1
        # create user seed file /opt/splunkforwarder/bin/splunk hash-passwd <password>
        sudo bash -c 'cat > /opt/splunkforwarder/etc/system/local/user-seed.conf <<EOF
[user_info]
USERNAME = admin
HASHED_PASSWORD = \$6\$pMJ0oz6BPTB6vt6I\$eYStL/reA89frAKdlizTPdbp4A6TgsKLA23hBIjwWc5C0.0DbSzjn/07SrBRIYKOY.6t/.nxY2Um3VqImC8AB1
EOF'

        # ENABLE AUTO START ON REBOOT
        sudo ${SPLUNK_HOME}/bin/splunk enable boot-start --accept-license
        sudo ${SPLUNK_HOME}/bin/splunk add forward-server ${SPLUNK_FORWARDER_SERVER}

        # RECREATING USER CONFIG FILE AS IT GETS DELETED
        # HASHED PWD - $6$pMJ0oz6BPTB6vt6I$eYStL/reA89frAKdlizTPdbp4A6TgsKLA23hBIjwWc5C0.0DbSzjn/07SrBRIYKOY.6t/.nxY2Um3VqImC8AB1
        # create user seed file /opt/splunkforwarder/bin/splunk hash-passwd <password>
        sudo bash -c 'cat > /opt/splunkforwarder/etc/system/local/user-seed.conf  <<EOF
[user_info]
USERNAME = admin
HASHED_PASSWORD = \$6\$pMJ0oz6BPTB6vt6I\$eYStL/reA89frAKdlizTPdbp4A6TgsKLA23hBIjwWc5C0.0DbSzjn/07SrBRIYKOY.6t/.nxY2Um3VqImC8AB1
EOF'

        # Create Splunk Monitor Folder 
        sudo bash -c 'cat > /opt/splunkforwarder/etc/system/local/inputs.conf  <<EOF
[default]
host=spark-aurora-metrics-pr
[monitor:///var/log/hadoop-yarn/containers/.../splunk_metrics.log]
queueSize=4MB
source=distributor-aur-pr
sourcetype=spark:metric
index=us_west_prod_power_platform
crcSalt=<SOURCE>
EOF'
        # Create Splunk limits file
        sudo bash -c 'cat > /opt/splunkforwarder/etc/system/local/limits.conf  <<EOF
[thruput]
maxKBps = 0
EOF'
        # RESTART SPLUNK SERVICE
        sudo ${SPLUNK_HOME}/bin/splunk restart
    fi

    logging 'Script exiting successfully.' 'INFO'
    exit 0
}
main "$@"
