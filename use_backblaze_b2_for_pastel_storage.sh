#!/bin/bash

# Define Backblaze B2 credentials and bucket name from environment variables
B2_APP_KEY_ID="${B2_APP_KEY_ID:-}" # Set from environment variable
B2_APP_KEY="${B2_APP_KEY:-}" # Set from environment variable
BUCKET_NAME='Backblaze-share-drive' # Replace with your actual bucket name
MOUNT_POINT='/home/ubuntu/Backblaze'

# Check if rclone is installed; if not, install it
if ! command -v rclone &> /dev/null; then
  sudo apt update
  sudo apt install -y rclone
fi

# Configure rclone with B2 information
rclone config create myb2bucket b2 account "$B2_APP_KEY_ID" key "$B2_APP_KEY"

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount Backblaze B2 bucket with optimized settings
rclone mount myb2bucket:"$BUCKET_NAME" "$MOUNT_POINT" \
  --vfs-cache-mode full \ # Full cache mode might be beneficial for latency
  --vfs-cache-max-age 3h \ # Adjust based on typical file access patterns
  --vfs-cache-max-size 20G \ # Increase based on available local storage
  --b2-chunk-size 64M \
  --buffer-size 64M \ # Increase buffer size for better performance
  --multi-thread-streams 4 \ # Enable multi-threading, adjust based on testing
  --retries 5 \
  --low-level-retries 15 \
  --daemon

# Add to crontab to remount on reboot
(crontab -l; echo "@reboot $0") | crontab -

# Check if sqlite3 CLI tool is installed; if not, install it
if ! command -v sqlite3 &> /dev/null; then
  sudo apt update
  sudo apt install -y sqlite3
fi

DESTINATION_FILE='/home/ubuntu/Backblaze/p2pdata/data001.sqlite3'

# Check the current page size
CURRENT_PAGE_SIZE=$(sqlite3 "$DESTINATION_FILE" "PRAGMA page_size;")

# Apply persistent PRAGMA settings to the database
if [ "$CURRENT_PAGE_SIZE" -ne 65536 ]; then
  sqlite3 "$DESTINATION_FILE" <<EOF
PRAGMA page_size = 65536; -- Max size (64KB)
PRAGMA journal_mode = WAL;
VACUUM;
EOF
else
  sqlite3 "$DESTINATION_FILE" <<EOF
PRAGMA journal_mode = WAL;
EOF
fi

# Apply non-persistent PRAGMA settings to the database (uncomment as needed for testing)
sqlite3 "$DESTINATION_FILE" <<EOF
-- PRAGMA synchronous = NORMAL; -- Reducing the synchronous level can improve write performance but might reduce durability.
-- PRAGMA cache_size = -524288; -- Increasing the cache size to 512MB to reduce reads from remote storage.
-- PRAGMA busy_timeout = 5000; -- A longer busy timeout of 5 seconds to help with contention issues.
-- PRAGMA wal_autocheckpoint = 1000; -- Fine-tuning the autocheckpoint frequency to 1000 pages to help manage the WAL file size.
EOF

# Copy pastel data to Backblaze, if it doesn't already exist there
mkdir -p /home/ubuntu/Backblaze/p2pdata
SOURCE_FILE='/home/ubuntu/.pastel/p2pdata/data001.sqlite3'

if [ ! -f "$DESTINATION_FILE" ]; then
  if [ -f "$SOURCE_FILE" ]; then
    mv "$SOURCE_FILE" "$DESTINATION_FILE"
  else
    echo "Source file does not exist: $SOURCE_FILE"
    exit 1
  fi
else
  echo "Destination file already exists: $DESTINATION_FILE"
  exit 1 # Handle this situation by exiting with an error
fi

# Create symbolic link to Backblaze so that pastel can use it transparently
SYMLINK_PATH='/home/ubuntu/.pastel/p2pdata/data001.sqlite3'
if [ -L "$SYMLINK_PATH" ]; then
  echo "Symbolic link already exists: $SYMLINK_PATH"
else
  ln -s /home/ubuntu/Backblaze/p2pdata/data001.sqlite3 "$SYMLINK_PATH"
fi
