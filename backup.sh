#! /bin/bash

set -e
set -o pipefail

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "Deleting older backups"
rm -rf *.bak *.csv *.tar *.tar.gz ./partitions

mkdir ./partitions

if test -z "${SKIP_PARTITIONS}" 
then
    # Dump old measurements partitions
    # https://github.com/pgpartman/pg_partman/blob/master/doc/pg_partman.md#scripts

    # First, with --nodrop to ensure that they're uploaded to s3
    echo "Dumping old measurements partitions with --nodrop"
    dump_partition.py \
        --schema archive \
        --connection "dbname=gorge host=${PGHOST} user=${PGUSER} password=${PGPASSWORD}" \
        --output ./partitions \
        --nodrop \
        --dump_database gorge

    echo "Uploading old measurements partitions to s3"
    aws s3 cp \
        --storage-class STANDARD_IA \
        --recursive \
        ./partitions \
        s3://${S3_BUCKET}/${S3_PREFIX}partitions_$(date +"%Y-%m-%d")/

    # Second time we really drop them
    echo "Dumping and dropping old measurements partitions "
    dump_partition.py \
        --schema archive \
        --connection "dbname=gorge host=${PGHOST} user=${PGUSER} password=${PGPASSWORD}" \
        --output ./partitions \
        --nohashfile \
        --dump_database gorge
fi

# This is required because pg_cron uses postgres database
echo "Creating dump of postgres database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f postgres.bak postgres

echo "Creating dump of wwguide database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f wwguide.bak wwguide

echo "Creating dump of gorge database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f gorge.bak gorge

echo "Creating dump of gorge database without measurements..."
pg_dump -Fc --no-owner --no-privileges --no-password --exclude-table-data '*measurements*' -f gorge_without_measurements.bak gorge

echo "Creating one-week measurements dump of gorge database..."
psql --no-password --dbname=gorge -c "\copy (SELECT * FROM measurements WHERE timestamp > NOW() - INTERVAL '7 DAY') TO '/app/measurements.csv'"

echo "Taring all backups together"
tar czvf backup.tar.gz *.bak *.csv

echo "Uploading dump to ${S3_BUCKET}"
cat backup.tar.gz | aws s3 cp - s3://${S3_BUCKET}/${S3_PREFIX}backup_$(date +"%Y-%m-%dT%H:%M:%SZ").tar.gz --storage-class STANDARD_IA || exit 2
echo "SQL backup uploaded successfully"

echo "Deleting current backups"
rm -rf *.bak *.csv *.tar *.tar.gz ./partitions
