#! /bin/sh

set -e

VERSION=$1

docker login docker.pkg.github.com -u ${GITHUB_USER} -p ${GITHUB_TOKEN}
docker push docker.pkg.github.com/whitewater-guide/gorge/gorge:latest
docker push docker.pkg.github.com/whitewater-guide/gorge/gorge:${VERSION}
