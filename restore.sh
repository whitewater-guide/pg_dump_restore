#! /bin/bash

set -e
set -o pipefail

export PGPASSWORD=${POSTGRES_PASSWORD}

if test -z "${SKIP_DOWNLOAD}" 
then
    echo "[restore] Finding latest backup"
    LATEST_BACKUP=$(aws s3api list-objects-v2 --bucket "${S3_BUCKET}" --prefix "${S3_PREFIX}backup" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output=text)

    echo "[restore] Fetching ${LATEST_BACKUP} from S3"
    aws s3 cp s3://${S3_BUCKET}/${LATEST_BACKUP} backup.tar.gz

    echo "[restore] Extracting backup contents"
    tar -xzvf backup.tar.gz
fi

if [ -f postgres.bak ]; then
    echo "[restore] Restoring postgres database..."
    pg_restore -d postgres -Fc --clean postgres.bak || true
    echo "[restore] Restored postgres"
else
    echo "[restore] postgres backup not found"
fi

if [ -f wwguide.bak ]; then
    echo "[restore] Restoring wwguide database..."
    pg_restore -d wwguide -Fc --clean wwguide.bak || true
    echo "[restore] Restored wwguide"
else
    echo "[restore] wwguide backup not found"
fi

if test -z "${SKIP_GORGE}" 
then
    if [ -f gorge.bak ]; then
        echo "[restore] Restoring gorge database..."
        # psql -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
        pg_restore -d gorge -Fc --clean gorge.bak || true
        echo "[restore] Restored gorge"
    else
        echo "[restore] gorge backup not found"
    fi
fi

rm -rf *.bak *.csv *.tar *.tar.gz ./partitions
echo "[restore] Deleted current backups"
