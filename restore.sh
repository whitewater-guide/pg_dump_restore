#! /bin/bash

set -e
set -o pipefail

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "Finding latest backup"
LATEST_BACKUP=$(aws s3api list-objects-v2 --bucket "${S3_BUCKET}" --prefix "${S3_PREFIX}backup" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output=text)

echo "Fetching ${LATEST_BACKUP} from S3"
aws s3 cp s3://${S3_BUCKET}/${LATEST_BACKUP} backup.tar

echo "Extracting backup contents"
tar -xzvf backup.tar.gz

echo "Restoring wwguide database..."
pg_restore -d wwguide -Fc --clean wwguide.bak || true
echo "Restored wwguide"

if test -z "${SKIP_GORGE}" 
then
    echo "Restoring gorge database..."
    # psql -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
    pg_restore -d gorge -Fc --clean gorge.bak || true
    echo "Restored gorge"
fi

rm -rf *.bak *.csv *.tar *.tar.gz
echo "Deleted current backups"
