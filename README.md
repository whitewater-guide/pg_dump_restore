This docker image is used to backup and restore whitewater.guide databases.

Based on https://github.com/whitewater-guide/postgres

Available via https://github.com/orgs/whitewater-guide/packages/container/package/pg_dump_restore

## Expected environment variables:

### Common:

- `S3_BUCKET` - bucket where backups are stored. Just bucket name, without protocol
- `S3_PREFIX` - s3 path prefix ending with `/`, defaults to `v3/`
- `PGHOST` - postgres host to backup from/restore to
- `PGUSER` - postgres user
- `POSTGRES_PASSWORD` - postgres password, note different style (`POSTGRES_` not `PG`)

### Backup:

- `SKIP_PARTITIONS` - if set, won't archive measurements partitions
- `SKIP_SYNAPSE` - if set, won't backup synapse database
- `KEEP_BACKUP_FILES` - if set, won't delete backup files, so the can be used immediately to restore to different database

### Restore:

- `SKIP_GORGE` - if set, won't restore gorge database
- `SKIP_SYNAPSE` - if set, won't restore synapse database
- `SKIP_DOWNLOAD` - if set, won't download dump from s3 and will use local files created by backup script
