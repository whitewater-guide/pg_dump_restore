#! /bin/sh

set -e

docker build -t docker.pkg.github.com/whitewater-guide/pg_dump_restore/pg_dump_restore:latest .
