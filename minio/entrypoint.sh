#!/bin/bash

# Start cron in background
crond -b

# Wait a bit for MinIO to start, then run initial tiering
(
  sleep 60
  echo "Running initial tiering setup..."
  /usr/local/bin/tiering-minio.sh
) &

# Start MinIO with original command
exec minio "$@"
