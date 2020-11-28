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
pg_dump -h db -U postgres -Fc --no-owner --data-only --exclude-schema '*timescale*' -f wwguide.bak wwguide

echo "Creating dump of gorge database..."
pg_dump -h db -U postgres -Fc --no-owner --data-only --table measurements -f gorge.bak gorge

echo "Taring all backups together"
tar cvf backup.tar *.bak

echo "Uploading dump to $S3_BUCKET"
cat backup.tar | aws s3 cp - s3://$S3_BUCKET/$S3_PREFIX/4aws_$(date +"%Y-%m-%dT%H:%M:%SZ").tar || exit 2
echo "SQL backup uploaded successfully"

echo "Deleting current backups"
rm -rf *.bak *.csv *.tar
