#!/bin/bash -x

set -o errexit -o nounset -o pipefail

# Use Anaconda POWER environment
export PYSPARK_PYTHON=/predix/anaconda2/envs/power/bin/python

echo "spark.driver.extraClassPath    /predix/datafabric/power/aws/1.11.272/*:/predix/genie/emr/emr-5.13.0/jars/hadoop-lzo/lib/*:/predix/genie/emr/emr-5.13.0/jars/hadoop/hadoop-aws.jar:/predix/genie/emr/emr-5.13.0/aws/emr/emrfs/conf:/predix/genie/emr/emr-5.13.0/aws/emr/emrfs/lib/*:/predix/genie/emr/emr-5.13.0/aws/emr/s3-dist-cp/lib/*" >> ${SPARK_CONF_DIR}/spark-defaults.conf
echo "spark.executor.extraClassPath    /predix/datafabric/power/aws/1.11.272/*:/predix/genie/emr/emr-5.13.0/jars/hadoop-lzo/lib/*:/predix/genie/emr/emr-5.13.0/jars/hadoop/hadoop-aws.jar:/predix/genie/emr/emr-5.13.0/aws/emr/emrfs/conf:/predix/genie/emr/emr-5.13.0/aws/emr/emrfs/lib/*:/predix/genie/emr/emr-5.13.0/aws/emr/s3-dist-cp/lib/*" >> ${SPARK_CONF_DIR}/spark-defaults.conf
