#!/bin/bash -x

set -o errexit -o nounset -o pipefail

APP_ID=hadoop-2.7.3
APP_NAME=hadoop-2.7.3
export HADOOP_DEPENDENCIES_DIR=${GENIE_APPLICATION_DIR}/${APP_ID}/dependencies
export HADOOP_HOME=${HADOOP_DEPENDENCIES_DIR}/${APP_NAME}

tar -xf ${HADOOP_DEPENDENCIES_DIR}/${APP_NAME}.tar.gz -C ${HADOOP_DEPENDENCIES_DIR}

# Sync AWS EMR libs
AWS_DIR=${HADOOP_DEPENDENCIES_DIR}/aws
aws s3 sync s3://${S3_BUCKET}/genie/clusters/${GENIE_CLUSTER_ID}/aws/ ${AWS_DIR}/ --region $AWS_REGION
aws s3 sync s3://${S3_BUCKET}/genie/clusters/${GENIE_CLUSTER_ID}/rpm/ ${HADOOP_DEPENDENCIES_DIR}/rpm/ --region $AWS_REGION

# Install LZO rpm
sudo /usr/bin/yum -y localinstall ${HADOOP_DEPENDENCIES_DIR}/rpm/hadoop-lzo-0.4.19-1.amzn1.x86_64.rpm

# Export Hadoop environment
export HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop"
export HADOOP_LIBEXEC_DIR="${HADOOP_HOME}/libexec"
export LD_LIBRARY_PATH="${HADOOP_HOME}/lib/native:/usr/lib/hadoop-lzo/lib/native"

# AWS configurations
export JAVA_LIBRARY_PATH="/usr/lib/hadoop-lzo/lib/native"
export HADOOP_CLASSPATH="/usr/lib/hadoop-lzo/lib/*"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/aws-java-sdk/*"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/emrfs/conf"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/emrfs/lib/*"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/emrfs/auxlib/*"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/ddb/lib/emr-ddb-hadoop.jar"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/goodies/lib/emr-hadoop-goodies.jar"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/kinesis/lib/emr-kinesis-hadoop.jar"
export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:${AWS_DIR}/emr/s3-dist-cp/lib/*"

# Disable yarn.timeline-service.enabled due to: at org.apache.spark.deploy.SparkSubmit.main(SparkSubmit.scala) Caused by: java.lang.ClassNotFoundException: com.sun.jersey.api.client.config.ClientConfig
xmlstarlet ed --inplace -u /"configuration/property[name='yarn.timeline-service.enabled']"/value -v 'false' ${GENIE_CLUSTER_DIR}/config/yarn-site.xml
/bin/cp --force ${GENIE_CLUSTER_DIR}/config/* ${HADOOP_CONF_DIR}/

# Remove the zip to save space
rm ${HADOOP_DEPENDENCIES_DIR}/${APP_NAME}.tar.gz