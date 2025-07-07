#!/usr/bin/env bash
# Tiering script for MinIO hot/cold

set -e
export PATH=/usr/local/bin:$PATH

MC=/usr/local/bin/mc
ALIAS=minio

# Wait for MinIO to be ready
echo "Waiting for MinIO to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1; then
    echo "MinIO is ready!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

# Configure alias (edit endpoint if remote)
$MC alias set $ALIAS http://localhost:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

# hot/ -> cold/ after 60 days
$MC find $ALIAS/hot --older-than 60d --exec "$MC mv {} $ALIAS/cold/{}"

# Larger than 10MB & older than 3d -> cold
$MC find $ALIAS/hot --larger-than 10MB --older-than 3d --exec "$MC mv {} $ALIAS/cold/{}"

# temp/ cleanup after 7 days
$MC find $ALIAS/temp --older-than 7d --exec "$MC rm {}"

echo "$(date '+%F %T') Tiering run completed"
