#!/usr/bin/env bash
# Tiering script for MinIO hot/cold

set -e

# Install mc if not present
if ! command -v mc &> /dev/null; then
    echo "Installing MinIO client..."
    wget https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
    chmod +x /usr/local/bin/mc
fi

MC=/usr/local/bin/mc
ALIAS=minio

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
for i in {1..30}; do
  if curl -s http://minio:9000/minio/health/live > /dev/null 2>&1; then
    echo "MinIO is ready!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Configure alias (usando hostname do container)
echo "Configuring MinIO client..."
$MC alias set $ALIAS http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# # hot/ -> cold/ after 60 days
# $MC find $ALIAS/hot --older-than 60d --exec "$MC mv {} $ALIAS/cold/{}"

# # Larger than 10MB & older than 3d -> cold
# $MC find $ALIAS/hot --larger 10MB --older-than 3d --exec "$MC mv {} $ALIAS/cold/{}"

# temp/ cleanup after 7 days
$MC find $ALIAS/temp --older-than 7d --exec "$MC rm {}"

echo "$(date '+%F %T') Tiering run completed"
