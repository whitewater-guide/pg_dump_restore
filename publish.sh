#! /bin/sh

set -e

VERSION=$1

docker login docker.pkg.github.com -u ${GITHUB_USER} -p ${GITHUB_TOKEN}
docker push docker.pkg.github.com/whitewater-guide/pg_dump_restore/pg_dump_restore:latest
docker tag docker.pkg.github.com/whitewater-guide/pg_dump_restore/pg_dump_restore:latest docker.pkg.github.com/whitewater-guide/pg_dump_restore/pg_dump_restore:${VERSION}
docker push docker.pkg.github.com/whitewater-guide/pg_dump_restore/pg_dump_restore:${VERSION}
