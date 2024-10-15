#!/usr/bin/env bash

# Function to perform backup
backup() {
  TIMESTAMP=$(date +"%Y%m%d%H%M%S")
  BACKUP_FILE="homeassistant_backup_$TIMESTAMP.tar.gz"
  tar -czvf /tmp/$BACKUP_FILE /config
  if [ -n "$S3_ENDPOINT_URL" ]; then
    aws s3 cp /tmp/$BACKUP_FILE s3://$S3_BUCKET/$BACKUP_FILE --endpoint-url $S3_ENDPOINT_URL
  else
    aws s3 cp /tmp/$BACKUP_FILE s3://$S3_BUCKET/$BACKUP_FILE
  fi
  rm /tmp/$BACKUP_FILE
}

# If 'backup' argument is passed, perform backup
if [ "$1" == "backup" ]; then
  # Load options
  CONFIG_PATH=/data/options.json
  AWS_ACCESS_KEY_ID=$(jq --raw-output '.aws_access_key_id' $CONFIG_PATH)
  AWS_SECRET_ACCESS_KEY=$(jq --raw-output '.aws_secret_access_key' $CONFIG_PATH)
  S3_BUCKET=$(jq --raw-output '.s3_bucket' $CONFIG_PATH)
  S3_REGION=$(jq --raw-output '.s3_region' $CONFIG_PATH)
  S3_ENDPOINT_URL=$(jq --raw-output '.s3_endpoint_url // empty' $CONFIG_PATH)

  # Export AWS credentials
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION

  # Perform backup
  backup
else
  # First time setup: write cron job and start cron

  # Load options
  CONFIG_PATH=/data/options.json
  BACKUP_INTERVAL_HOURS=$(jq --raw-output '.backup_interval_hours' $CONFIG_PATH)

  # Write to cron file
  echo "0 */$BACKUP_INTERVAL_HOURS * * * /run.sh backup >> /proc/1/fd/1 2>&1" > /etc/crontabs/root

  # Start cron in foreground
  crond -f -l 2
fi
