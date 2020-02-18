FROM postgres:11.6-alpine

WORKDIR /app

RUN apk update && \
    # install s3 tools
    apk add python py2-pip && \
    pip install awscli && \
    # install go-cron
    apk add curl && \
    curl -L --insecure https://github.com/odise/go-cron/releases/download/v0.0.6/go-cron-linux.gz | zcat > /usr/local/bin/go-cron && \
    chmod u+x /usr/local/bin/go-cron && \
    # cleanup
    apk del curl py2-pip && \
    rm -rf /var/cache/apk/*

COPY backup.sh restore.sh run.sh ./

ENTRYPOINT ["/app/run.sh"]
