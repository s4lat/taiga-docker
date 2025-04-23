#!/usr/bin/env sh

# Check if .env exists
if [ ! -f ./.env ]; then
    echo "Error: .env file not found in current directory"
    exit 1
fi

# Load environment variables
set -a
. ./.env
set +a

set -x

# create backup dir
BACKUP_DIR="taiga-backup-$(date +'%Y-%m-%d-%H-%M-%S')"
mkdir -p "$BACKUP_DIR" && \

# make db backup
docker compose exec taiga-db pg_dump -U "$POSTGRES_USER" taiga > "$BACKUP_DIR/taiga-db-backup.sql" && \

# create media backup archive
docker compose exec taiga-back tar czf taiga-media-backup.tar.gz media && \

# copy media backup archive
docker compose cp taiga-back:/taiga-back/taiga-media-backup.tar.gz "$BACKUP_DIR/" && \

# archive the entire backup directory
tar czf "${BACKUP_DIR}.tar.gz" "$BACKUP_DIR" && \

# remove original backup directory
rm -rf "$BACKUP_DIR" && \

echo "Backup completed. Archive created: ${BACKUP_DIR}.tar.gz"