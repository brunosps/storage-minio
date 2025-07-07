FROM minio/minio:latest

# Copy tiering script
COPY --chmod=755 tiering-minio.sh /usr/local/bin/tiering-minio.sh

# Create data directories
RUN mkdir -p /data-hot /data-cold

HEALTHCHECK --start-period=1m CMD curl -f http://localhost:9000/minio/health/live || exit 1

# Default command for Dokku (pode ser sobrescrito por variáveis de ambiente)
CMD ["server", "/data-hot", "/data-cold", "--console-address", ":9001"]
