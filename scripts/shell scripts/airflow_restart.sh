#!/bin/bash

echo "Current User is"
whoami

echo "Assuming ubuntu user"
sudo -i -u ubuntu  bash << EOF

echo "Current User is"
whoami

echo "--------------- Restart Airflow Scheduler ---------------"
sudo systemctl status airflow-scheduler
sudo systemctl stop   airflow-scheduler
sudo systemctl status airflow-scheduler

sleep 2

sudo systemctl start  airflow-scheduler
sudo systemctl status airflow-scheduler
echo "---------- Restart Airflow Scheduler Completed ----------"


EOF
