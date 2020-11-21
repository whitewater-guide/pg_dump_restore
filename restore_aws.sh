#! /bin/sh

# This script is 

set -e
set -o pipefail

echo "Finding latest backup"
LATEST_BACKUP=$(aws s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "production/backup" --query 'reverse(sort_by(Contents, &LastModified))[:1].Key' --output=text)

echo "Fetching ${LATEST_BACKUP} from S3"
aws s3 cp s3://$S3_BUCKET/$LATEST_BACKUP backup.tar

echo "Extracting backup contents"
tar -xvf backup.tar

echo "Restoring wwguide database..."
pg_restore -d wwguide -Fc --data-only --disable-triggers --schema public wwguide.bak  || true
echo "Restored wwguide database from ${LATEST_BACKUP}"

echo "Restoring gorge database..."
pg_restore -d gorge -Fc --data-only --disable-triggers --table measurements gorge.bak  || true
echo "Restore complete from ${LATEST_BACKUP}"
rm -rf *.bak *.csv *.tar
echo "Deleted current backups"