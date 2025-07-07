FROM minio/minio:latest

# Copy tiering script
COPY --chmod=755 tiering-minio.sh /usr/local/bin/tiering-minio.sh

HEALTHCHECK --start-period=1m CMD curl -f http://localhost:9000/minio/health/live || exit 1
