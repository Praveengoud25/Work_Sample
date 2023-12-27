#!/bin/bash -x
 
set -o errexit -o nounset -o pipefail 
 
start_dir=`pwd` 
cd `dirname ${BASH_SOURCE[0]}` 
SPARK_BASE=`pwd` 
cd $start_dir 
 
export SPARK_DAEMON_JAVA_OPTS="-verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps" 
export SPARK_DEPS=${SPARK_BASE}/dependencies 
export SPARK_VERSION="2.3.2" 

tar xzf ${SPARK_DEPS}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz -C ${SPARK_DEPS} 

# Set the required environment variables: spark-env.sh
export SPARK_HOME=${SPARK_DEPS}/spark-${SPARK_VERSION}-bin-hadoop2.7 
export SPARK_CONF_DIR=${SPARK_HOME}/conf 
export SPARK_LOG_DIR=${GENIE_JOB_DIR} 
export SPARK_LOG_FILE=spark.log 
export SPARK_LOG_FILE_PATH=${GENIE_JOB_DIR}/${SPARK_LOG_FILE} 
export CURRENT_JOB_WORKING_DIR=${GENIE_JOB_DIR} 
export CURRENT_JOB_TMP_DIR=${CURRENT_JOB_WORKING_DIR}/tmp

# Make Sure Script is on the Path 
export PATH=$PATH:${SPARK_HOME}/bin

# Get EMR hive-site.xml
aws s3 cp s3://${S3_BUCKET}/genie/clusters/${GENIE_CLUSTER_ID}/conf/spark/hive-site.xml ${SPARK_CONF_DIR}/hive-site.xml --region $AWS_REGION || echo "WARNING: hive-site.xml not found!"
# Overwrite hadoop-aws.jar with the one from EMR
aws s3 cp s3://${S3_BUCKET}/genie/clusters/${GENIE_CLUSTER_ID}/jars/hadoop-aws.jar ${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws.jar --region $AWS_REGION

# Export PYTHONPATH for Genie
export PYTHONPATH="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/pyspark.zip:${SPARK_HOME}/python/lib/py4j-0.10.3-src.zip"

# Create spark defaults file
AWS_DEPENDENCIES_DIR=${HADOOP_DEPENDENCIES_DIR}/aws
cat > ${SPARK_CONF_DIR}/spark-defaults.conf <<EOF
#spark.master                     yarn
spark.driver.extraClassPath      :/usr/lib/hadoop-lzo/lib/*:${HADOOP_HOME}/share/hadoop/tools/lib/hadoop-aws.jar:${AWS_DEPENDENCIES_DIR}/aws-java-sdk/*:${AWS_DEPENDENCIES_DIR}/emr/emrfs/conf:${AWS_DEPENDENCIES_DIR}/emr/emrfs/lib/*:${AWS_DEPENDENCIES_DIR}/emr/emrfs/auxlib/*:${AWS_DEPENDENCIES_DIR}/emr/s3-dist-cp/lib/*
spark.driver.extraLibraryPath    ${HADOOP_HOME}/lib/native:/usr/lib/hadoop-lzo/lib/native
spark.executor.extraClassPath    :/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*:/usr/share/aws/emr/security/conf:/usr/share/aws/emr/security/lib/*
spark.executor.extraLibraryPath  /usr/lib/hadoop/lib/native:/usr/lib/hadoop-lzo/lib/native
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs:///var/log/spark/apps
spark.history.fs.logDirectory    hdfs:///var/log/spark/apps
spark.sql.warehouse.dir          hdfs:///user/spark/warehouse
spark.yarn.historyServer.address \${hadoopconf-yarn.resourcemanager.hostname}:18080
spark.history.ui.port            18080
spark.shuffle.service.enabled    true
spark.yarn.dist.files            ${SPARK_CONF_DIR}/hive-site.xml
spark.dynamicAllocation.enabled  true
spark.hadoop.yarn.timeline-service.enabled false
#spark.driver.extraJavaOptions    -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70 -XX:+CMSClassUnloadingEnabled -XX:OnOutOfMemoryError='kill -9 %p'
#spark.executor.extraJavaOptions  -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=70 -XX:MaxHeapFreeRatio=70 -XX:+CMSClassUnloadingEnabled -XX:OnOutOfMemoryError='kill -9 %p'
#spark.executor.memory            5120M
#spark.executor.cores             4
EOF

# Delete the tarball to save space 
rm ${SPARK_DEPS}/spark-${SPARK_VERSION}-bin-hadoop2.7.tgz
