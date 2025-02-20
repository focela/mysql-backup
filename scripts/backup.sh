#!/bin/sh

set -eu
set -o pipefail

# Load environment variables
source ./env.sh

# Define variables
TIMESTAMP=$(date +"%Y-%m-%dT%H:%M:%S")
S3_URI_BASE="s3://${S3_BUCKET}/${S3_PREFIX}/${MYSQL_DATABASE}_${TIMESTAMP}.dump"

# Create MySQL database backup
echo "Creating backup of $MYSQL_DATABASE database..."
mysqldump -h "$MYSQL_HOST" \
          --port "$MYSQL_PORT" \
          -u "$MYSQL_USER" \
          -p"$MYSQL_PASSWORD" \
          -d "$MYSQL_DATABASE" \
          $MSDUMP_EXTRA_OPTS \
          > db.dump

# Encrypt backup if passphrase is provided
if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  gpg --symmetric --batch --passphrase "$PASSPHRASE" db.dump
  rm db.dump
  LOCAL_FILE="db.dump.gpg"
  S3_URI="${S3_URI_BASE}.gpg"
else
  LOCAL_FILE="db.dump"
  S3_URI="$S3_URI_BASE"
fi

# Upload backup to S3
echo "Uploading backup to $S3_BUCKET..."
aws $aws_args s3 cp "$LOCAL_FILE" "$S3_URI"
rm "$LOCAL_FILE"

echo "Backup complete."

# Remove old backups if retention policy is set
if [ -n "$BACKUP_KEEP_DAYS" ]; then
  SEC=$((86400 * BACKUP_KEEP_DAYS))
  DATE_FROM_REMOVE=$(date -d "@$(($(date +%s) - SEC))" +%Y-%m-%d)
  BACKUPS_QUERY="Contents[?LastModified<='${DATE_FROM_REMOVE} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $S3_BUCKET..."
  aws $aws_args s3api list-objects \
    --bucket "$S3_BUCKET" \
    --prefix "$S3_PREFIX" \
    --query "$BACKUPS_QUERY" \
    --output text \
    | xargs -n1 -t -I '{}' aws $aws_args s3 rm s3://"$S3_BUCKET"/{}

  echo "Removal complete."
fi
