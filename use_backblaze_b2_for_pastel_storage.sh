#!/bin/bash

# Define Backblaze B2 credentials and bucket name
B2_ACCOUNT_ID=''
B2_APP_KEY='' 
BUCKET_NAME='Backblaze-share-drive' # Replace with your actual bucket name
MOUNT_POINT='/home/ubuntu/Backblaze'

# Check if rclone is installed; if not, install it
if ! command -v rclone &> /dev/null; then
  sudo apt update
  sudo apt install -y rclone
fi

# Configure rclone with B2 information
rclone config create myb2bucket b2 account "$B2_ACCOUNT_ID" key "$B2_APP_KEY"

# Create mount point if it doesn't exist
mkdir -p "$MOUNT_POINT"

# Mount Backblaze B2 bucket
rclone mount myb2bucket:"$BUCKET_NAME" "$MOUNT_POINT" --vfs-cache-mode writes &

# Add to crontab to remount on reboot
(crontab -l; echo "@reboot $0") | crontab -

# Copy pastel data to Backblaze
mkdir -p /home/ubuntu/Backblaze/p2pdata
mv /home/ubuntu/.pastel/p2pdata/data001.sqlite3 /home/ubuntu/Backblaze/p2pdata/data001.sqlite3

# Create symbolic link to Backblaze so that pastel can use it transparently 
ln -s /home/ubuntu/Backblaze/p2pdata/data001.sqlite3 /home/ubuntu/.pastel/p2pdata/data001.sqlite3
