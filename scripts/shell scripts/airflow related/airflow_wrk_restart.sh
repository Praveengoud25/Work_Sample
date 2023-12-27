#!/bin/bash

echo "Current User is"
whoami

echo "--------------- Restart Airflow worker ---------------"
sudo systemctl status airflow-worker
sudo systemctl stop   airflow-worker
sudo systemctl status airflow-worker

sleep 2

sudo systemctl start  airflow-worker
sudo systemctl status airflow-worker
echo "---------- Restart Airflow Scheduler Completed ----------"


echo "--------------- Restart Airflow webserver ---------------"
sudo systemctl status airflow-webserver
sudo systemctl stop   airflow-webserver
sudo systemctl status airflow-webserver

sleep 2

sudo systemctl start  airflow-webserver
sudo systemctl status airflow-webserver
echo "---------- Restart Airflow webserver Completed ----------"


echo "--------------- Restart Airflow flower ---------------"
sudo systemctl status airflow-flower
sudo systemctl stop   airflow-flower
sudo systemctl status airflow-flower

sleep 2

sudo systemctl start  airflow-flower
sudo systemctl status airflow-flower
echo "---------- Restart Airflow flower Completed ----------"
