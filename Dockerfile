FROM postgres:12.4-alpine

WORKDIR /app

RUN apk update && \
    # install s3 tools
    apk add aws-cli curl && \
    # install go-cron
    curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && \
    chmod u+x /usr/local/bin/go-cron && \
    # cleanup
    apk del curl && \
    rm -rf /var/cache/apk/*

COPY backup.sh restore.sh run.sh backup_partial.sh restore_partial.sh ./

ENTRYPOINT ["/app/run.sh"]
