#!/usr/bin/env sh

set -x

# create backup dir
BACKUP_DIR="taiga-backup-$(date +'%Y-%m-%d-%H-%M-%S')"
mkdir -p "$BACKUP_DIR" && \

# make db backup
docker exec taiga-docker-taiga-db-1 pg_dump -U taiga taiga > "$BACKUP_DIR/taiga-db-backup.sql" && \

# create media backup archive
docker exec taiga-docker-taiga-back-1 tar czf taiga-media-backup.tar.gz media && \

# copy media backup archive
docker cp taiga-docker-taiga-back-1:/taiga-back/taiga-media-backup.tar.gz "$BACKUP_DIR/" && \

# archive the entire backup directory
tar czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR" && \

# remove original backup directory
rm -rf "$BACKUP_DIR" && \

echo "Backup completed. Archive created: ${BACKUP_DIR}.tar.gz"