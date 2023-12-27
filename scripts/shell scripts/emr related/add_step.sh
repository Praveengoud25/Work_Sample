#!/bin/bash -x
# Script to work around missing EMR Steps API in Terraform
# The script waits for the cluster to get into WAITING state and then runs the command (similar to Steps API)
# Usage: ./add_step.sh s3://mybucket/myscript,arg1,arg2
# Example: ./add_step.sh s3://dev-blitz-orchestration/andromeda/bootstrap/andromeda_register_cluster.sh,1234567890,dev-blitz-orchestration

CLUSTER_ID=$(jq -r '.jobFlowId' /mnt/var/lib/info/job-flow.json)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/|sed 's/.$//')
SCRIPT_S3_PATH=$(echo $1 | perl -pe 's/^(.*?),(.*)$/\1/')
SCRIPT=$(echo ${SCRIPT_S3_PATH} | perl -pe 's/^.*\/(.*)$/\1/')
ARG_STRING=$(echo $1 | perl -pe 's/^(.*?),(.*)$/\2/')
ARGS=$(echo ${ARG_STRING} | perl -pe 's/,/ /g')

echo "start add_step">>/tmp/boot_strap_ex_info.txt
echo $CLUSTER_ID>>/tmp/boot_strap_ex_info.txt
echo $REGION>>/tmp/boot_strap_ex_info.txt
echo $SCRIPT_S3_PATH>>/tmp/boot_strap_ex_info.txt
echo $SCRIPT>>/tmp/boot_strap_ex_info.txt
echo $ARG_STRING>>/tmp/boot_strap_ex_info.txt
echo $ARGS>>/tmp/boot_strap_ex_info.txt
echo "stop add_step">>/tmp/boot_strap_ex_info.txt

go_to_background(){
while true
do
	if [ "$(aws emr describe-cluster --cluster-id ${CLUSTER_ID} --region ${REGION} | jq ".Cluster.Status.State" -r)" == "WAITING" ]
	then
		aws s3 cp ${SCRIPT_S3_PATH} /tmp/${SCRIPT}
		chmod +x /tmp/${SCRIPT}
		sudo /tmp/${SCRIPT} ${ARGS}
		break
	fi
	sleep 10
done
}

go_to_background &
