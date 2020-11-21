#! /bin/sh

set -e
set -o pipefail

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD

echo "Finding latest backup"
LATEST_BACKUP=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "production/partial" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output=text)

echo "Fetching ${LATEST_BACKUP} from S3"
aws s3 cp s3://$S3_BUCKET/$LATEST_BACKUP partial.tar

echo "Extracting backup contents"
tar -xvf partial.tar

echo "Restoring wwguide database..."
# When --create option is used, the database named with -d is used only to issue the initial DROP DATABASE and CREATE DATABASE commands. 
# All data is restored into the database name that appears in the archive.
psql -h db -U postgres -d postgres -c "REVOKE CONNECT ON DATABASE wwguide FROM public;"
psql -h db -U postgres -d postgres -c "SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'wwguide';"
pg_restore -h db -U postgres -d postgres -Fc --clean --create wwguide.bak  || true
psql -h db -U postgres -d postgres -c "GRANT CONNECT ON DATABASE wwguide TO public;"
echo "Restored wwguide database from ${LATEST_BACKUP}"

echo "Restoring gorge database..."
psql -h db -U postgres -d postgres -c "REVOKE CONNECT ON DATABASE gorge FROM public;"
psql -h db -U postgres -d postgres -c "SELECT pid, pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'gorge';"
pg_restore -h db -U postgres -d postgres -Fc --clean --create gorge_schema.bak  || true
psql -h db -U postgres -d gorge -c "INSERT INTO schema_migrations (version, dirty) VALUES (1, false);"
psql -h db -U postgres -d gorge -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"
psql -h db -U postgres -d gorge -c "SELECT create_hypertable('measurements', 'timestamp');"
psql -h db -U postgres -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
psql -h db -U postgres -d postgres -c "GRANT CONNECT ON DATABASE gorge TO public;"
echo "Restore complete from ${LATEST_BACKUP}"
rm -rf *.bak *.csv *.tar
echo "Deleted current backups"