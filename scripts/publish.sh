#! /bin/sh

set -e

VERSION=$1

echo ${CR_PAT} | docker login ghcr.io -u ${GITHUB_USER} --password-stdin
docker push ghcr.io/whitewater-guide/pg_dump_restore:latest
docker tag ghcr.io/whitewater-guide/pg_dump_restore:latest ghcr.io/whitewater-guide/pg_dump_restore:${VERSION}
docker push ghcr.io/whitewater-guide/pg_dump_restore:${VERSION}
