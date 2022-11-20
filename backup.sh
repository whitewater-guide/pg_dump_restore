#! /bin/bash

set -e
set -o pipefail

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "[backup] Deleting older backups"
rm -rf *.bak *.csv *.tar *.tar.gz ./partitions

mkdir ./partitions

if test -z "${SKIP_PARTITIONS}" 
then
    # Dump old measurements partitions
    # https://github.com/pgpartman/pg_partman/blob/master/doc/pg_partman.md#scripts

    # First, with --nodrop to ensure that they're uploaded to s3
    echo "[backup] Dumping old measurements partitions with --nodrop"
    dump_partition.py \
        --schema archive \
        --connection "dbname=gorge host=${PGHOST} user=${PGUSER} password=${PGPASSWORD}" \
        --output ./partitions \
        --nodrop \
        --dump_database gorge

    echo "[backup] Uploading old measurements partitions to s3"
    aws s3 cp \
        --storage-class STANDARD_IA \
        --recursive \
        ./partitions \
        s3://${S3_BUCKET}/${S3_PREFIX}partitions_$(date +"%Y-%m-%d")/

    # Second time we really drop them
    echo "[backup] Dumping and dropping old measurements partitions "
    dump_partition.py \
        --schema archive \
        --connection "dbname=gorge host=${PGHOST} user=${PGUSER} password=${PGPASSWORD}" \
        --output ./partitions \
        --nohashfile \
        --dump_database gorge
fi

# This is required because pg_cron uses postgres database
echo "[backup] Creating dump of postgres database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f postgres.bak postgres

echo "[backup] Creating dump of wwguide database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f wwguide.bak wwguide

if test -z "${SKIP_SYNAPSE}" 
then
    echo "[backup] Creating dump of synapse database..."
    pg_dump -Fc --no-owner --no-privileges --no-password -f synapse.bak synapse
fi

echo "[backup] Creating dump of gorge database..."
pg_dump -Fc --no-owner --no-privileges --no-password -f gorge.bak gorge

echo "[backup] Creating dump of gorge database without measurements..."
pg_dump -Fc --no-owner --no-privileges --no-password --exclude-table-data '*measurements*' -f gorge_without_measurements.bak gorge

echo "[backup] Creating one-week measurements dump of gorge database..."
psql --no-password --dbname=gorge -c "\copy (SELECT * FROM measurements WHERE timestamp > NOW() - INTERVAL '7 DAY') TO '/app/measurements.csv'"

echo "[backup] Taring all backups together"
tar czvf backup.tar.gz *.bak *.csv

echo "[backup] Uploading dump to ${S3_BUCKET}"
cat backup.tar.gz | aws s3 cp - s3://${S3_BUCKET}/${S3_PREFIX}backup_$(date +"%Y-%m-%dT%H_%M_%SZ").tar.gz --storage-class STANDARD_IA || exit 2
echo "[backup] SQL backup uploaded successfully"

if test -z "${KEEP_BACKUP_FILES}" 
then
    echo "[backup] Deleting current backups"
    rm -rf *.bak *.csv *.tar *.tar.gz ./partitions
fi
