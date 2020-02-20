#! /bin/sh

set -e
set -o pipefail

# env vars needed for aws tools
export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$S3_REGION

export PGPASSWORD=$POSTGRES_PASSWORD

echo "Deleting older backups"
rm -rf *.bak *.csv *.tar

echo "Creating dump of wwguide database..."
pg_dump -h db -U postgres -Fc -f wwguide.bak wwguide

echo "Creating dump of gorge database without data..."
pg_dump -h db -U postgres -Fc --schema-only --no-owner --section pre-data --disable-triggers --table measurements --table jobs --table schema_migrations -f gorge_schema.bak gorge

echo "Creating one-day measurements dump of gorge database..."
psql --host db --username postgres --dbname=gorge -c "\copy (SELECT * FROM measurements WHERE timestamp > NOW() - INTERVAL '1 DAY') TO '/app/measurements.csv'"
echo "Taring all backups together"
tar cvf backup.tar *.bak *.csv

echo "Uploading dump to $S3_BUCKET"
cat backup.tar | aws s3 cp - s3://$S3_BUCKET/$S3_PREFIX/partial_$(date +"%Y-%m-%dT%H:%M:%SZ").tar || exit 2
echo "SQL backup uploaded successfully"

echo "Deleting current backups"
rm -rf *.bak *.csv *.tar
