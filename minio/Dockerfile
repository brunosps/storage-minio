FROM minio/minio:latest

# Create data directories
RUN mkdir -p /data-hot /data-cold

# Copy tiering script
COPY --chmod=755 tiering-minio.sh /usr/local/bin/tiering-minio.sh

# Expose ports
EXPOSE 9000 9001

# Health check
HEALTHCHECK --start-period=1m CMD curl -f http://localhost:9000/minio/health/live || exit 1

# Start MinIO
CMD ["server", "/data-hot", "/data-cold", "--console-address", ":9001"]
