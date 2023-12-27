#!/bin/bash -x

set -o errexit -o nounset -o pipefail

export SPARK_APP_NAME=spark-2.3.0
export SPARK_BASE=/predix/genie/applications/${SPARK_APP_NAME}
export SPARK_DAEMON_JAVA_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps"
export SPARK_VERSION="2.3.0"
export HADOOP_APP_NAME=hadoop-2.8.3
export EMR_RELEASE=`aws emr describe-cluster --cluster-id ${GENIE_CLUSTER_ID} --region us-west-2 --query 'Cluster.ReleaseLabel' --output text`
export AWS_DEPENDENCIES_DIR=/predix/genie/emr/${EMR_RELEASE}
export AWS_DIR=${AWS_DEPENDENCIES_DIR}/aws
export JARS_DIR=${AWS_DEPENDENCIES_DIR}/jars
export HADOOP_HOME=/predix/genie/applications/${HADOOP_APP_NAME}/hadoop

# Set the required environment variables: spark-env.sh
export SPARK_CLUSTER_CONFIG_DIR=${GENIE_APPLICATION_DIR}/${SPARK_APP_NAME}/config
export SPARK_HOME=${SPARK_BASE}/spark
export SPARK_CONF_DIR=${SPARK_CLUSTER_CONFIG_DIR}
export SPARK_LOG_DIR=${GENIE_JOB_DIR}
export SPARK_LOG_FILE=spark.log
export SPARK_LOG_FILE_PATH=${GENIE_JOB_DIR}/${SPARK_LOG_FILE}
export CURRENT_JOB_WORKING_DIR=${GENIE_JOB_DIR}
export CURRENT_JOB_TMP_DIR=${CURRENT_JOB_WORKING_DIR}/tmp
export SPARK_DEPENDENCIES_DIR=${GENIE_APPLICATION_DIR}/${SPARK_APP_NAME}/dependencies

#create cluster specific spark config directory
mkdir -p ${SPARK_CLUSTER_CONFIG_DIR}
mkdir -p ${SPARK_DEPENDENCIES_DIR}

#copy default spark configurations into SPARK_CLUSTER_CONFIG_DIR
cp ${SPARK_HOME}/conf/* ${SPARK_CLUSTER_CONFIG_DIR}

# Make Sure Script is on the Path
export PATH=${PATH}:${SPARK_HOME}/bin
HIVE_SITE=""

# Get EMR hive-site.xml
cp /predix/genie/clusters/${GENIE_CLUSTER_ID}/conf/spark/hive-site.xml ${SPARK_CONF_DIR}/hive-site.xml && HIVE_SITE=${SPARK_CONF_DIR}/hive-site.xml

# Export PYTHONPATH for Genie
export PYTHONPATH="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-src.zip"

# Create spark defaults file
cat > ${SPARK_CONF_DIR}/spark-defaults.conf <<EOF
#spark.master                              yarn
spark.driver.extraLibraryPath              ${HADOOP_HOME}/lib/native:${JARS_DIR}/hadoop-lzo/lib/native
spark.executor.extraLibraryPath            ${HADOOP_HOME}/lib/native:${JARS_DIR}/hadoop-lzo/lib/native
spark.eventLog.enabled                     true
spark.eventLog.dir                         hdfs:///var/log/spark/apps
spark.history.fs.logDirectory              hdfs:///var/log/spark/apps
spark.history.fs.cleaner.maxAge            1d
spark.sql.warehouse.dir                    hdfs:///user/spark/warehouse
spark.yarn.historyServer.address           \${hadoopconf-yarn.resourcemanager.hostname}:18080
spark.history.ui.port                      18080
spark.shuffle.service.enabled              true
spark.yarn.dist.files                      ${HIVE_SITE}
spark.dynamicAllocation.enabled            true
spark.hadoop.yarn.timeline-service.enabled false
EOF
