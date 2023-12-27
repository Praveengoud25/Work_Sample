#!/bin/bash
set -ex

SOURCE_BUCKETPATH="s3://gep-stag-orchestration-deps-us-west-2/airflow/bootstrap"
AIRFLOW_SCRIPT_PATH="/opt/airflow/scripts"

cleanup() {
	echo "Cleanup..."
	sudo rm -rf /etc/cron.d/airflow-timepublisher
	sudo rm -rf /tmp/airflow-timepublisher.log
	sudo rm -rf /opt/airflow/scripts/airflow-timepublisher.sh
}

cleanup

sudo aws s3 cp $SOURCE_BUCKETPATH/airflow-install-alarm.sh  $AIRFLOW_SCRIPT_PATH/.
sudo aws s3 cp $SOURCE_BUCKETPATH/airflow-install-chrony.sh $AIRFLOW_SCRIPT_PATH/.
sudo aws s3 cp $SOURCE_BUCKETPATH/airflow-timepublisher.sh  $AIRFLOW_SCRIPT_PATH/.


sudo sudo chmod +x $AIRFLOW_SCRIPT_PATH
sudo sudo chmod +x $AIRFLOW_SCRIPT_PATH/.
sudo bash $AIRFLOW_SCRIPT_PATH/airflow-install-alarm.sh
sudo bash $AIRFLOW_SCRIPT_PATH/airflow-install-chrony.sh
sudo bash $AIRFLOW_SCRIPT_PATH/airflow-timepublisher.sh