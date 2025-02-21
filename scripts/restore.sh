#!/bin/sh

set -u  # `-e` omitted intentionally, but reason unknown
set -o pipefail

# Load environment variables
source ./env.sh

# Define S3 base URI
S3_URI_BASE="s3://${S3_BUCKET}/${S3_PREFIX}"

# Determine file type based on encryption status
if [ -z "$PASSPHRASE" ]; then
  FILE_TYPE=".dump"
else
  FILE_TYPE=".dump.gpg"
fi

# Determine the backup key suffix
if [ $# -eq 1 ]; then
  TIMESTAMP="$1"
  KEY_SUFFIX="${MYSQL_DATABASE}_${TIMESTAMP}${FILE_TYPE}"
else
  echo "Finding latest backup..."
  KEY_SUFFIX=$(
    aws $aws_args s3 ls "${S3_URI_BASE}/${MYSQL_DATABASE}" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
fi

# Fetch backup from S3
echo "Fetching backup from S3..."
aws $aws_args s3 cp "${S3_URI_BASE}/${KEY_SUFFIX}" "db${FILE_TYPE}"

# Decrypt backup if passphrase is provided
if [ -n "$PASSPHRASE" ]; then
  echo "Decrypting backup..."
  gpg --decrypt --batch --passphrase "$PASSPHRASE" db.dump.gpg > db.dump
  rm db.dump.gpg
fi

# Define MySQL connection options
CONN_OPTS="-h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE"

# Restore backup
echo "Restoring from backup..."
mysql $CONN_OPTS < db.dump
rm db.dump

echo "Restore complete."
