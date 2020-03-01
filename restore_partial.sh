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
LATEST_BACKUP=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "production/partial" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output=text)

echo "Fetching ${LATEST_BACKUP} from S3"
aws s3 cp s3://$S3_BUCKET/$LATEST_BACKUP partial.tar

echo "Extracting backup contents"
tar -xvf partial.tar

echo "Restoring wwguide database..."
psql -h db -U postgres -d wwguide -c "REVOKE CONNECT ON DATABASE wwguide FROM public;"
psql -h db -U postgres -d wwguide -c "SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();"
pg_restore -h db -U postgres -d wwguide -Fc --clean --create wwguide.bak  || true
psql -h db -U postgres -d wwguide -c "GRANT CONNECT ON DATABASE wwguide TO public;"
echo "Restored wwguide database from ${LATEST_BACKUP}"

echo "Restoring gorge database..."
psql -h db -U postgres -d gorge -c "REVOKE CONNECT ON DATABASE gorge FROM public;"
psql -h db -U postgres -d gorge -c "SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = current_database() AND pid <> pg_backend_pid();"
pg_restore -h db -U postgres -d gorge -Fc --clean --create gorge_schema.bak  || true
psql -h db -U postgres -d gorge -c "INSERT INTO schema_migrations (version, dirty) VALUES (1, false);"
psql -h db -U postgres -d gorge -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -h db -U postgres -d gorge -c "SELECT create_hypertable('measurements', 'timestamp');"
psql -h db -U postgres -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
psql -h db -U postgres -d gorge -c "GRANT CONNECT ON DATABASE gorge TO public;"
echo "Restore complete from ${LATEST_BACKUP}"
rm -rf *.bak *.csv *.tar
echo "Deleted current backups"