#!/bin/bash -x

CWD=$(dirname $0)

sudo /etc/init.d/chrony restart

# Load custom parameters
PARAMS_FILE=$CWD/../install_parameters.cfg
[[ -f $PARAMS_FILE ]] && source $PARAMS_FILE

# Parameters
export PATH=$PATH:/usr/local/bin
export AIRFLOW_HOME=${AIRFLOW_HOME:-/opt/airflow}
export PYTHONPATH=$AIRFLOW_HOME/libs:$AIRFLOW_HOME/plugins

AIRFLOW_ROLE="${AIRFLOW_ROLE:-all}"
AIRFLOW_QUEUE="${AIRFLOW_QUEUE-analytics}"
AIRFLOW_SERVICE_USER="${AIRFLOW_SERVICE_USER:-airflow}"
AIRFLOW_SERVICE_GROUP="${AIRFLOW_SERVICE_GROUP:-airflow}"
ANALYTIC_STATE_DB_HOST="${ANALYTIC_STATE_DB_HOST:-changeme}"
ANALYTIC_STATE_DB_RO_HOST="${ANALYTIC_STATE_DB_RO_HOST:-changeme}"
ANALYTIC_STATE_DB_SCHEMA="${ANALYTIC_STATE_DB_SCHEMA:-changeme}"
ANALYTIC_STATE_DB_USER="${ANALYTIC_STATE_DB_USER:-changeme}"
ANALYTIC_STATE_DB_PASSWORD="${ANALYTIC_STATE_DB_PASSWORD:-changeme}"

ANALYTIC_CACHE_DB_NAME="${ANALYTIC_CACHE_DB_NAME:-changeme}"
ANALYTIC_CACHE_DB_USER="${ANALYTIC_CACHE_DB_USER:-changeme}"
ANALYTIC_CACHE_DB_PASSWORD="${ANALYTIC_CACHE_DB_PASSWORD:-changeme}"
ANALYTIC_CACHE_DB_HOST="${ANALYTIC_CACHE_DB_HOST:-changeme}"

OM_RABBITMQ_HOST="${OM_RABBITMQ_HOST:-changeme}"
OM_SQS_HOST="${OM_SQS_HOST:-changeme}"
OM_SQS_BACKFILL_HOST="${OM_SQS_BACKFILL_HOST:-changeme}"
AIRFLOW_METADATA_DB_CONNECT_FROM="${AIRFLOW_METADATA_DB_CONNECT_FROM:-changeme}"
AIRFLOW_METADATA_DB_NAME="${AIRFLOW_METADATA_DB_NAME:-airflow_metadata_db}"
AIRFLOW_METADATA_DB_PASSWORD="${AIRFLOW_METADATA_DB_PASSWORD:-changeme}"
AIRFLOW_METADATA_DB_USER="${AIRFLOW_METADATA_DB_USER:-airflow_metadata_user}"
AWS_REGION="$(curl -s http://instance-data/latest/meta-data/placement/availability-zone/|sed 's/.$//')"
AIRFLOW_METADATA_DB_MASTER_PASSWORD="${AIRFLOW_METADATA_DB_MASTER_PASSWORD:-changeme}"
AIRFLOW_METADATA_DB_HOST="${AIRFLOW_METADATA_DB_HOST:-localhost}"
AIRFLOW_METADATA_DB_MASTER_USER="${AIRFLOW_METADATA_DB_MASTER_USER:-postgres}"
AIRFLOW_WEB_FQDN="${AIRFLOW_WEB_FQDN=-localhost}"
DYNAMODB_ENDPOINT="dynamodb.${AWS_REGION}.amazonaws.com"
DYNAMODB_PORT="${DYNAMODB_PORT:-8000}"
FERNET_KEY="${FERNET_KEY:-changeme}"
GENIE_ENDPOINT="${GENIE_ENDPOINT:-genie-host}"
GENIE_PORT="${GENIE_PORT:-80}"
REDIS_ENDPOINT="${REDIS_ENDPOINT:-redis-host}"
S3_ARTIFACT_BUCKET="${S3_ARTIFACT_BUCKET:-gep-test-airflow-bootstrap-bucket}"
S3_LOG_BUCKET="${S3_LOG_BUCKET:-gep-test-airflow-log-bucket}"
TSQS_ENDPOINT="${TSQS_ENDPOINT:-time-series.dev.gepowerpredix.com}"
TMP_DIR="${TMP_DIR:-$CWD/../tmp}"
UAA_OAUTH_ENDPOINT="${UAA_OAUTH_ENDPOINT:-f6d0524d-28d1-4af8-a21c-3c779790aff4.predix-uaa.run.aws-usw02-pr.ice.predix.io}"
UAA_OAUTH_CLIENT_ID="${UAA_OAUTH_CLIENT_ID:-powersit_ts}"
UAA_OAUTH_CLIENT_SECRET="${UAA_OAUTH_CLIENT_SECRET:-xxxx}"
S3_PROPEL_BUCKET="${S3_PROPEL_BUCKET:-xxx}"
CUSTOMER_APM_TENANT_ID="${CUSTOMER_APM_TENANT_ID:-empty}"


update_jinja_templates () {
  local jinja_template="$1"
  local jinja_params="$2"
  local jinja_file="$3"
  cat <<EOH | python > ${jinja_file}
import jinja2, json
params = json.loads('''${jinja_params}''')
print jinja2.Template(open('${jinja_template}').read()).render(params)
EOH
}

# Create a temporary working directory
[[ ! -d "$TMP_DIR" ]] && mkdir $TMP_DIR

# Create service account
useradd -r -s /sbin/nologin -d $AIRFLOW_HOME $AIRFLOW_SERVICE_USER

# Create AIRFLOW_HOME directory structure
for i in $AIRFLOW_HOME $AIRFLOW_HOME/logs $AIRFLOW_HOME/scripts; do
  [[ ! -d $i ]] && install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 00750 -d $i
done

# Create $AIRFLOW_HOME/airflow.cfg
template=$CWD/templates/airflow.cfg.jinja
tmp_file=$TMP_DIR/airflow.cfg

# Not required as of now
# "smtp_user": "airflow",
# "smtp_password": "airflow",
params=$(cat <<EOH
{
  "airflow_home": "${AIRFLOW_HOME}",
  "airflow_dags_folder": "${AIRFLOW_HOME}/dags",
  "airflow_base_log_folder": "${AIRFLOW_HOME}/logs",
  "airflow_max_threads": "100",
  "airflow_queue": "${AIRFLOW_QUEUE}",
  "airflow_metadata_db_name": "${AIRFLOW_METADATA_DB_NAME}",
  "airflow_metadata_db_user": "${AIRFLOW_METADATA_DB_USER}",
  "airflow_metadata_db_password": "${AIRFLOW_METADATA_DB_PASSWORD}",
  "airflow_metadata_db_host": "${AIRFLOW_METADATA_DB_HOST}",
  "airflow_web_fqdn": "${AIRFLOW_WEB_FQDN}",
  "fernet_key": "${FERNET_KEY}",
  "redis_endpoint": "${REDIS_ENDPOINT}",
  "remote_log_conn_id": "s3_default",
  "s3_log_bucket": "${S3_LOG_BUCKET}",
  "smtp_host": "localhost",
  "smtp_ssl": "False",
  "smtp_starttls": "True",
  "smtp_port": "25",
  "smtp_mail_from": "airflow@example.com"
}
EOH
)
update_jinja_templates $template "$params" $tmp_file
install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 00640 $TMP_DIR/airflow.cfg $AIRFLOW_HOME/airflow.cfg

# Create /etc/profile.d/airflow.sh
template=$CWD/templates/airflow.sh.jinja
tmp_file=$TMP_DIR/airflow_functions.sh
params=$(cat <<EOH
{
  "airflow_home": "${AIRFLOW_HOME}",
  "airflow_service_user": "${AIRFLOW_SERVICE_USER}",
  "python_path": "${PYTHONPATH}"
}
EOH
)
update_jinja_templates $template "$params" $tmp_file
install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 00644 $TMP_DIR/airflow_functions.sh /etc/profile.d/airflow_functions.sh

# Create directory for dags, libs and plugins
for i in dags libs plugins; do
  [[ ! -d "$AIRFLOW_HOME/$i" ]] && mkdir -m 777 $AIRFLOW_HOME/$i
done

# Create service parameters file
cat > $TMP_DIR/airflow <<EOH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This file is the environment file for Airflow. Put this file in /etc/default/airflow per default
# configuration of the systemd unit files.
#
AIRFLOW_CONFIG=${AIRFLOW_HOME}/airflow.cfg
AIRFLOW_HOME=${AIRFLOW_HOME}
PYTHONPATH=${AIRFLOW_HOME}/libs:${AIRFLOW_HOME}/plugins
#
# required setting, 0 sets it to unlimited. Scheduler will get restart after every X runs
SCHEDULER_RUNS=5
EOH
install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0644 $TMP_DIR/airflow /etc/default/airflow

# Create /etc/cron.d/airflow_log_cleanup
echo "*/60 * * * * $AIRFLOW_SERVICE_USER $AIRFLOW_HOME/scripts/log_cleanup.sh" > $TMP_DIR/airflow_log_cleanup
install -o root -g root -m 00644 $TMP_DIR/airflow_log_cleanup /etc/cron.d/airflow_log_cleanup

# Create /etc/cron.d/airflow_sync
echo "*/1 * * * * $AIRFLOW_SERVICE_USER $AIRFLOW_HOME/scripts/sync_all.sh" > $TMP_DIR/airflow_cron
install -o root -g root -m 00644 $TMP_DIR/airflow_cron /etc/cron.d/airflow_sync

# Create $AIRFLOW_HOME/scripts/sync_all.sh
template=$CWD/templates/sync_all.sh.jinja
tmp_file=$TMP_DIR/sync_all.sh
params=$(cat <<EOH
{
  "airflow_home": "${AIRFLOW_HOME}",
  "customer_apm_tenant_id": "${CUSTOMER_APM_TENANT_ID}",
  "aws_region": "${AWS_REGION}",
  "s3_propel_bucket" : "${S3_PROPEL_BUCKET}"
}
EOH
)
update_jinja_templates $template "$params" $tmp_file
install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 00750 $TMP_DIR/sync_all.sh $AIRFLOW_HOME/scripts/sync_all.sh
runuser -s /bin/bash -l $AIRFLOW_SERVICE_USER -c $AIRFLOW_HOME/scripts/sync_all.sh

# Create $AIRFLOW_HOME/scripts/log_cleanup.sh for airflow worker
cat > $AIRFLOW_HOME/scripts/log_cleanup.sh <<EOH
#!/bin/bash
find $AIRFLOW_HOME/logs/ -mindepth 1 -mmin +1440 -type f -delete
find $AIRFLOW_HOME/logs/ -mindepth 1 -mmin +1440 -empty -type d -delete
EOH
chmod 0750 $AIRFLOW_HOME/scripts/log_cleanup.sh
chown airflow:airflow $AIRFLOW_HOME/scripts/log_cleanup.sh

#create logrotate.d/airflow config
cat >/etc/logrotate.d/airflow <<EOH
/var/log/airflow/*.log
{
  maxsize 100M
  daily
  su root root
  rotate 7

  dateext
  dateformat .%Y-%m-%d

  compress
  nodelaycompress

  copytruncate
  create 660 airflow airflow

  missingok
  notifempty
  lastaction
  HOSTNAME=`hostname`
       aws s3 sync $AIRFLOW_HOME/logs s3://$S3_LOG_BUCKET/airflow/app_logs/$HOSTNAME/ --exclude "*" --include "*.gz"
  endscript
}
EOH
  
# Create symbolic link to syslog directory
[[ ! -L /var/log/airflow ]] && ln -s $AIRFLOW_HOME/logs -T /var/log/airflow

# Evaluate AIRFLOW_ROLE
case $AIRFLOW_ROLE in
  scheduler)

  # Initialize airflow meta database
  export MYSQL_HOST="$AIRFLOW_METADATA_DB_HOST"
  export MYSQL_PWD="$AIRFLOW_METADATA_DB_MASTER_PASSWORD"
  
  AIRFLOW_METADATA_DB_EXISTS=$(mysql -u $AIRFLOW_METADATA_DB_MASTER_USER --skip-column-names --batch -e "show databases LIKE '${AIRFLOW_METADATA_DB_NAME}';" | wc -l)

  if [[ "$AIRFLOW_METADATA_DB_EXISTS" == 1 ]]; then
    airflow upgradedb
  else
    mysql -u $AIRFLOW_METADATA_DB_MASTER_USER -e "CREATE DATABASE $AIRFLOW_METADATA_DB_NAME;"
    mysql -u $AIRFLOW_METADATA_DB_MASTER_USER -e "CREATE USER '${AIRFLOW_METADATA_DB_USER}'@'${AIRFLOW_METADATA_DB_CONNECT_FROM}' IDENTIFIED BY '${AIRFLOW_METADATA_DB_PASSWORD}';"
    mysql -u $AIRFLOW_METADATA_DB_MASTER_USER -e "GRANT ALL ON $AIRFLOW_METADATA_DB_NAME.* TO '${AIRFLOW_METADATA_DB_USER}'@'${AIRFLOW_METADATA_DB_CONNECT_FROM}';"
    
    export MYSQL_PWD="$AIRFLOW_METADATA_DB_PASSWORD"
    airflow initdb
  fi

  # connections.py
  template=$CWD/templates/connections.py.jinja
  tmp_file=$TMP_DIR/tmp_connections.py
  params=$(cat <<EOH
{
  "analytic_state_db_host": "${ANALYTIC_STATE_DB_HOST}",
  "analytic_state_db_ro_host": "${ANALYTIC_STATE_DB_RO_HOST}",
  "analytic_state_db_name": "${ANALYTIC_STATE_DB_SCHEMA}",
  "analytic_state_db_user": "${ANALYTIC_STATE_DB_USER}",
  "analytic_state_db_password": "${ANALYTIC_STATE_DB_PASSWORD}",
  "analytic_cache_db_host": "${ANALYTIC_CACHE_DB_HOST}",
  "analytic_cache_db_name": "${ANALYTIC_CACHE_DB_NAME}",
  "analytic_cache_db_user": "${ANALYTIC_CACHE_DB_USER}",
  "analytic_cache_db_password": "${ANALYTIC_CACHE_DB_PASSWORD}",
  "om_rabbitmq_host": "om_rabbitmq_host_CHANGEME",
  "om_sqs_host": "om_sqs_host_CHANGEME",
  "om_sqs_backfill_host": "om_sqs_backfill_host_CHANGEME",
  "airflow_metadata_db_name": "${AIRFLOW_METADATA_DB_NAME}",
  "airflow_metadata_db_user": "${AIRFLOW_METADATA_DB_USER}",
  "airflow_metadata_db_password": "${AIRFLOW_METADATA_DB_PASSWORD}",
  "airflow_metadata_db_host": "${AIRFLOW_METADATA_DB_HOST}",
  "aws_region": "${AWS_REGION}",
  "genie_endpoint": "${GENIE_ENDPOINT}",
  "genie_port": "${GENIE_PORT}",
  "tsqs_endpoint": "${TSQS_ENDPOINT}",
  "uaa_oauth_endpoint": "${UAA_OAUTH_ENDPOINT}",
  "uaa_oauth_client_id": "${UAA_OAUTH_CLIENT_ID}",
  "uaa_oauth_client_secret": "${UAA_OAUTH_CLIENT_SECRET}"
}
EOH
)
    update_jinja_templates $template "$params" $tmp_file
    sed "s~om_sqs_host_CHANGEME~${OM_SQS_HOST}~" $TMP_DIR/tmp_connections.py > $TMP_DIR/connections.py
    sed "s~om_sqs_backfill_host_CHANGEME~${OM_SQS_BACKFILL_HOST}~" $TMP_DIR/tmp_connections.py > $TMP_DIR/connections.py
    python $TMP_DIR/connections.py
    cat > $TMP_DIR/airflow-scheduler.service <<EOH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=Airflow scheduler daemon %i
After=network.target

[Service]
Environment=SCHEDULER_LOC=${AIRFLOW_HOME}
Environment=AIRFLOW_CONFIG=${AIRFLOW_HOME}/airflow.cfg
Environment=AIRFLOW_HOME=${AIRFLOW_HOME}
Environment=PYTHONPATH=${AIRFLOW_HOME}/libs:${AIRFLOW_HOME}/plugins
# required setting, 0 sets it to unlimited. Scheduler will get restart after every X runs
Environment=SCHEDULER_RUNS=5

User=${AIRFLOW_SERVICE_USER}
Group=${AIRFLOW_SERVICE_GROUP}
Type=simple
ExecStart=/bin/bash -c 'exec /usr/local/bin/airflow scheduler -n 30 >> ${AIRFLOW_HOME}/logs/scheduler.log 2>&1'
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOH
  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0744 $TMP_DIR/airflow-scheduler.service /etc/systemd/system/airflow-scheduler.service

  systemctl enable airflow-scheduler
  systemctl start airflow-scheduler
  ;;
  worker)

  # Create /etc/cron.d/aero_rta_log_cleanup
  echo "*/60 * * * * $AIRFLOW_SERVICE_USER $AIRFLOW_HOME/scripts/aero_rta_log_cleanup.sh" > $TMP_DIR/aero_rta_log_cleanup
  install -o root -g root -m 00644 $TMP_DIR/aero_rta_log_cleanup /etc/cron.d/aero_rta_log_cleanup

  # Create /etc/cron.d/sync_aero_rta_cloudwatch_logs
  echo "*/5 * * * * $AIRFLOW_SERVICE_USER $AIRFLOW_HOME/scripts/sync_aero_rta_cloudwatch_logs.sh" > $TMP_DIR/sync_aero_rta_cloudwatch_logs
  install -o root -g root -m 00644 $TMP_DIR/sync_aero_rta_cloudwatch_logs /etc/cron.d/sync_aero_rta_cloudwatch_logs

  # Create $AIRFLOW_HOME/scripts/aero_rta_log_cleanup.sh for airflow worker
  cat > $AIRFLOW_HOME/scripts/aero_rta_log_cleanup.sh <<EOH
#!/bin/bash
find $AIRFLOW_HOME/logs/aero_rta_cloudwatch/ -mindepth 1 -mtime +1 -type f -delete
EOH
  chmod 0750 $AIRFLOW_HOME/scripts/aero_rta_log_cleanup.sh
  chown airflow:airflow $AIRFLOW_HOME/scripts/aero_rta_log_cleanup.sh

  # Create $AIRFLOW_HOME/scripts/sync_aero_rta_cloudwatch_logs.sh for airflow worker
  template=$CWD/templates/sync_aero_rta_cloudwatch_logs.sh.jinja
  tmp_file=$TMP_DIR/sync_aero_rta_cloudwatch_logs.sh
  params=$(cat <<EOH
{
  "aero_rta_cloudwatch_logs_path": "${AIRFLOW_HOME}/logs/aero_rta_cloudwatch",
  "s3_log_bucket_path" : "${S3_LOG_BUCKET}/aero_rta_cloudwatch/`hostname`",
  "aws_region": "${AWS_REGION}"
}
EOH
)
  update_jinja_templates $template "$params" $tmp_file
  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 00750 $TMP_DIR/sync_aero_rta_cloudwatch_logs.sh $AIRFLOW_HOME/scripts/sync_aero_rta_cloudwatch_logs.sh
  runuser -s /bin/bash -l $AIRFLOW_SERVICE_USER -c $AIRFLOW_HOME/scripts/sync_aero_rta_cloudwatch_logs.sh


  cat > $TMP_DIR/airflow-worker.service <<EOH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=Airflow celery worker daemon
After=network.target

[Service]
EnvironmentFile=/etc/default/airflow
User=${AIRFLOW_SERVICE_USER}
Group=${AIRFLOW_SERVICE_GROUP}
Type=simple
ExecStart=/bin/bash -c 'exec /usr/local/bin/airflow worker >> ${AIRFLOW_HOME}/logs/worker.log 2>&1'
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOH
  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0644 $TMP_DIR/airflow-worker.service /etc/systemd/system/airflow-worker.service

  cat > $TMP_DIR/airflow-flower.service <<EOH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=Airflow celery flower
After=network.target

[Service]
EnvironmentFile=/etc/default/airflow
User=${AIRFLOW_SERVICE_USER}
Group=${AIRFLOW_SERVICE_GROUP}
Type=simple
ExecStart=/bin/bash -c 'exec /usr/local/bin/airflow flower >> ${AIRFLOW_HOME}/logs/flower.log 2>&1'
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOH
  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0644 $TMP_DIR/airflow-flower.service /etc/systemd/system/airflow-flower.service

  cat > $TMP_DIR/airflow-webserver.service <<EOH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

[Unit]
Description=Airflow webserver daemon
After=network.target

[Service]
EnvironmentFile=/etc/default/airflow
User=${AIRFLOW_SERVICE_USER}
Group=${AIRFLOW_SERVICE_GROUP}
Type=simple
ExecStart=/bin/bash -c 'exec /usr/local/bin/airflow webserver --pid /run/airflow/webserver.pid >> ${AIRFLOW_HOME}/logs/webserver.log 2>&1'
Restart=on-failure
RestartSec=5s
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOH
  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0644 $TMP_DIR/airflow-webserver.service /etc/systemd/system/airflow-webserver.service

  install -o $AIRFLOW_SERVICE_USER -g $AIRFLOW_SERVICE_GROUP -m 0755 -d /run/airflow
  echo "D /run/airflow 0755 airflow airflow" > /etc/tmpfiles.d/airflow.conf

  for i in worker flower webserver; do
    systemctl enable airflow-$i
    systemctl start airflow-$i
  done
  ;;
  *)
    echo "ERROR: Invalid AIRFLOW_ROLE. Exiting..."
    exit 1
    ;;
esac
