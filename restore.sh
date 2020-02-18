#! /bin/sh

set -e
set -o pipefail

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER"

echo "Finding latest backup"
LATEST_BACKUP=$(aws s3 ls s3://$S3_BUCKET/$S3_PREFIX/ | sort | tail -n 1 | awk '{ print $4 }')

echo "Fetching ${LATEST_BACKUP} from S3"
aws s3 cp s3://$S3_BUCKET/$S3_PREFIX/${LATEST_BACKUP} backup.tar

echo "Extracting backup contents"
tar -xvf backup.tar

echo "Restoring wwguide database..."
pg_restore -h db -U postgres -d wwguide -Fc wwguide.bak
echo "Restored wwguide database"


echo "Restoring gorge database..."
psql  -h db -U postgres -d gorge  -c "SELECT timescaledb_pre_restore();"
pg_restore -h db -U postgres -d wwguide -Fc gorge.bak
psql  -h db -U postgres -d gorge  -c "SELECT timescaledb_post_restore();"
echo "Restore complete"
