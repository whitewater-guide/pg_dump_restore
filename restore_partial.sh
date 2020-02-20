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
pg_restore -h db -U postgres -d wwguide -Fc --clean --create gorge_schema.bak
psql --username "$POSTGRES_USER" -d gorge -c "INSERT INTO schema_migrations (version, dirty) VALUES (1, false);"
psql --username "$POSTGRES_USER" -d gorge -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql --username "$POSTGRES_USER" -d gorge -c "SELECT create_hypertable('measurements', 'timestamp');"
psql --username "$POSTGRES_USER" -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
echo "Restore complete"
rm -rf *.bak *.csv *.tar
echo "Deleted current backups"