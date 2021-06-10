FROM postgres:12.4-alpine

WORKDIR /app

RUN apk update && \
    # install s3 tools
    apk add aws-cli curl && \
    # cleanup
    rm -rf /var/cache/apk/*

# check installation
RUN aws --version

COPY ./*.sh ./
