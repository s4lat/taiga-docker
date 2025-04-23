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

# Prompt for backup archive path
read -p "Enter path to .tar.gz backup archive: " BACKUP_ARCHIVE

# Extract backup archive
BACKUP_DIR=$(mktemp -d)
tar -xvf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR" || { echo "Failed to extract archive"; exit 1; }

EXTRACTED=$BACKUP_DIR/$(ls $BACKUP_DIR | head -1)

# Run only the database to avoid migrations
docker compose up -d taiga-db --wait && \

# Copy the dump inside the container:
docker compose cp "$EXTRACTED/taiga-db-backup.sql" taiga-db:/taiga-db-backup.sql && \

# Access the container
docker compose exec -T taiga-db psql -U "$POSTGRES_USER" taiga < "$EXTRACTED/taiga-db-backup.sql" && \

# Up taiga-back for db migrations
docker compose up -d taiga-back && \

# copy media
docker compose cp "$EXTRACTED/taiga-media-backup.tar.gz" taiga-back:/taiga-media-backup.tar.gz && \
cat <<EOF | docker compose exec -T taiga-back /bin/bash
mv /taiga-media-backup.tar.gz /taiga-back/media
cd /taiga-back/media
tar -xzvf taiga-media-backup.tar.gz --strip 1
rm taiga-media-backup.tar.gz
chown -R taiga:taiga *
exit
EOF  && \

rm -rf "$BACKUP_DIR"  && \
echo "Backup restoration completed successfully"