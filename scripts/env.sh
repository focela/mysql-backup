#!/bin/bash

# Ensure essential environment variables are set before proceeding

# Check S3 bucket configuration
if [ -z "$S3_BUCKET" ]; then
  echo "Error: The S3_BUCKET environment variable is required." >&2
  exit 1
fi

# Check MySQL database configurations
if [ -z "$MYSQL_DATABASE" ]; then
  echo "Error: The MYSQL_DATABASE environment variable is required." >&2
  exit 1
fi

if [ -z "$MYSQL_USER" ]; then
  echo "Error: The MYSQL_USER environment variable is required." >&2
  exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "Error: The MYSQL_PASSWORD environment variable is required." >&2
  exit 1
fi

# Determine MySQL host configuration
if [ -z "$MYSQL_HOST" ]; then
  if [ -n "$MYSQL_PORT_3306_TCP_ADDR" ]; then
    MYSQL_HOST=$MYSQL_PORT_3306_TCP_ADDR
    MYSQL_PORT=$MYSQL_PORT_3306_TCP_PORT
  else
    echo "Error: The MYSQL_HOST environment variable is required." >&2
    exit 1
  fi
fi

# AWS S3 endpoint configuration
aws_args=""
if [ -n "$S3_ENDPOINT" ]; then
  aws_args="--endpoint-url $S3_ENDPOINT"
fi

# Export AWS credentials if provided
if [ -n "$S3_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID="$S3_ACCESS_KEY_ID"
fi

if [ -n "$S3_SECRET_ACCESS_KEY" ]; then
  export AWS_SECRET_ACCESS_KEY="$S3_SECRET_ACCESS_KEY"
fi

# Set default AWS region
export AWS_DEFAULT_REGION="$S3_REGION"

# Export MySQL password for compatibility
export MSPASSWORD="$MYSQL_PASSWORD"

# Ensure proper permissions and security best practices
umask 077
