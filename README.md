This docker image is used to backup and restore whitewater.guide databases.

Available via https://github.com/orgs/whitewater-guide/packages/container/package/pg_dump_restore

Expected environment variables:

- `S3_BUCKET` - bucket where backups are stored. Just bucket name, without protocol
- `S3_PREFIX` - s3 path prefix ending with `/`, defaults to `v3/`
- `PGHOST` - postgres host to backup from/restore to
- `PGUSER` - postgres user
- `POSTGRES_PASSWORD` - postgres password, note different style (`POSTGRES_` not `PG`)
- `SKIP_GORGE` - if set, won't restore gorge database
- `SKIP_PARTITIONS` - if set, won't archive measurements partitions
