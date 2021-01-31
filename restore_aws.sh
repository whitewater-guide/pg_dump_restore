#! /bin/sh

# This script is 

set -e
set -o pipefail

echo "Fetching ${BACKUP_URL}"
curl ${BACKUP_URL} -o backup.tar.gz

echo "Extracting backup contents"
tar -xzvf backup.tar.gz

echo "Restoring wwguide database..."
pg_restore -d wwguide -Fc --clean --schema public wwguide.bak || true
echo "Restored wwguide"

if test -z "$SKIP_GORGE" 
then
    echo "Restoring gorge database..."
    psql -d gorge -c "\copy measurements FROM '/app/measurements.csv'"
    echo "Restored gorge"
fi

rm -rf *.bak *.csv *.tar *.tar.gz
echo "Deleted current backups"
