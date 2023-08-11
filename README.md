# Use Backblaze B2 for Pastel Storage

This script is designed to configure and mount a Backblaze B2 bucket as a local filesystem on an Ubuntu machine. It also moves a specific Pastel data file to the Backblaze B2 bucket and creates a symbolic link to ensure transparent access to the file.

## Screenshot of Script

![Screenshot](screenshot.svg)

## Prerequisites

- Ubuntu machine
- Backblaze B2 account
- `rclone` installed (the script will install it if not present)

## Usage

1. **Edit the Script**: Open the `use_backblaze_b2_for_pastel_storage.sh` script and fill in the `B2_ACCOUNT_ID`, `B2_APP_KEY`, and `BUCKET_NAME` variables with your Backblaze B2 credentials and the name of the bucket you want to mount.

2. **Make the Script Executable**: Run the following command to make the script executable:

   ```bash
   chmod +x use_backblaze_b2_for_pastel_storage.sh
   ```

3. **Run the Script**: Execute the script with:

   ```bash
   ./use_backblaze_b2_for_pastel_storage.sh
   ```

## What the Script Does

- Checks if `rclone` is installed, and installs it if necessary.
- Configures `rclone` with the provided Backblaze B2 credentials.
- Mounts the specified Backblaze B2 bucket to `/home/ubuntu/Backblaze`.
- Moves the Pastel data file (`data001.sqlite3`) to the Backblaze B2 bucket.
- Creates a symbolic link from the original location to the new location on the Backblaze B2 bucket.
- Adds a crontab entry to remount the Backblaze B2 bucket at reboot.

## Notes

- Ensure that the specified bucket exists in your Backblaze B2 account.
- Ensure that the Pastel data file exists at the specified location before running the script.
- Handle the script with care, as it contains sensitive credentials.
