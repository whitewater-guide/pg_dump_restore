#! /bin/sh

# This script is 

set -e
set -o pipefail

echo "Fetching ${BACKUP_URL}"
curl ${BACKUP_URL} -o backup.tar

echo "Extracting backup contents"
tar -xvf backup.tar

echo "Restoring wwguide database..."
pg_restore -d wwguide -Fc --schema public wwguide.bak || true
echo "Restored wwguide database from ${LATEST_BACKUP}"

echo "Restoring gorge database..."
pg_restore -d gorge -Fc --table measurements --table jobs gorge.bak || true
echo "Restore complete from ${LATEST_BACKUP}"
rm -rf *.bak *.csv *.tar
echo "Deleted current backups"
