#!/bin/sh

set -eux
set -o pipefail

# Update package lists
apk update

# Install required dependencies
apk add --no-cache \
    mysql-client \
    gnupg \
    python3 \
    py3-pip \
    curl

# Install AWS CLI
pip3 install --no-cache-dir awscli --break-system-packages

# Install go-cron
GO_CRON_VERSION="0.0.5"
GO_CRON_ARCHIVE="go-cron_${GO_CRON_VERSION}_linux_${TARGETARCH}.tar.gz"
GO_CRON_URL="https://github.com/ivoronin/go-cron/releases/download/v${GO_CRON_VERSION}/${GO_CRON_ARCHIVE}"

curl -L "$GO_CRON_URL" -o "$GO_CRON_ARCHIVE"
tar xvf "$GO_CRON_ARCHIVE"
rm "$GO_CRON_ARCHIVE"
mv go-cron /usr/local/bin/go-cron
chmod u+x /usr/local/bin/go-cron

# Remove unnecessary packages after installation to reduce image size
apk del curl

# Cleanup cached files to optimize image size
rm -rf /var/cache/apk/*
