#! /bin/sh

set -e
set -o pipefail

export PGPASSWORD=$POSTGRES_PASSWORD

echo "Deleting older backups"
rm -rf *.bak *.csv *.tar *.tar.gz

echo "Creating dump of wwguide database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f wwguide.bak wwguide

echo "Creating dump of gorge database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f gorge.bak gorge

echo "Creating dump of gorge database without data..."
pg_dump -Fc --no-owner --no-privileges --no-password --schema-only --section pre-data --disable-triggers --table measurements --table jobs --table schema_migrations -f gorge_schema.bak gorge

echo "Creating one-week measurements dump of gorge database..."
psql --no-password --dbname=gorge -c "\copy (SELECT * FROM measurements WHERE timestamp > NOW() - INTERVAL '7 DAY') TO '/app/measurements.csv'"

echo "Taring all backups together"
tar czvf backup.tar.gz *.bak *.csv

echo "Uploading dump to $S3_BUCKET"
cat backup.tar.gz | aws s3 cp - s3://$S3_BUCKET/backup_$(date +"%Y-%m-%dT%H:%M:%SZ").tar.gz || exit 2
echo "SQL backup uploaded successfully"

echo "Deleting current backups"
rm -rf *.bak *.csv *.tar *.tar.gz
