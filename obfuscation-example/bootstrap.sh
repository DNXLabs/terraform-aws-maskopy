#!/bin/bash -e
set -o pipefail
export AWS_DEFAULT_REGION=$1
#set -x
# File:           bootstrap.sh
# Description:    Script to run data obfuscation for all the components.
#------------------------------------------------------------------------------------
if [ $# -eq 0 ]; then
    echo "No arguments supplied"
    exit 1
fi
touch bootstrap.log
echo "Starting bootstrap process" | tee -a bootstrap.log
RDS_ENDPOINT=$2
TARGET_PORT=$3
RDS_MASTER_USER=$4
DB_NAME=$5

psql \
    --host=${RDS_ENDPOINT} \
    --port=${TARGET_PORT} \
    --username=${RDS_MASTER_USER} \
    --dbname=${DB_NAME} \
    -c "\i obfuscate.sql" >> bootstrap.log

echo "Sending bootstrap log to S3: s3:/S3_BUCKET/MASKOPY/logs/bootstrap.log"
# aws s3 cp bootstrap.log s3:/S3_BUCKET/MASKOPY/logs/bootstrap.log --sse
exit 0
