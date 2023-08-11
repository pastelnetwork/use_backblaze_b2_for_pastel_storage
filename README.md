# Use Backblaze B2 for Pastel Storage

This script is designed to configure and mount a Backblaze B2 bucket as a local filesystem on an Ubuntu machine, and optimize the SQLite database for remote access. It also moves a specific Pastel data file to the Backblaze B2 bucket and creates a symbolic link to ensure transparent access to the file. This allows Pastel Supernode operators to easily scale their storage without spending a fortune on a huge SSD for their VPS instance.



## Prerequisites

- Ubuntu machine
- Backblaze B2 account
- `rclone` and `sqlite3` CLI tool installed (the script will install them if not present)

## Usage

1. **Edit the Script**: Open the `use_backblaze_b2_for_pastel_storage.sh` script and fill in the `B2_APP_KEY_ID`, `B2_APP_KEY`, and `BUCKET_NAME` variables with your Backblaze B2 credentials and the name of the bucket you want to mount.

2. **Make the Script Executable**: Run the following command to make the script executable:

   ```bash
   chmod +x use_backblaze_b2_for_pastel_storage.sh
   ```

3. **Run the Script**: Execute the script with:

   ```bash
   ./use_backblaze_b2_for_pastel_storage.sh
   ```

## What the Script Does

- Checks if `rclone` and `sqlite3` CLI tool are installed, and installs them if necessary.
- Configures `rclone` with the provided Backblaze B2 credentials.
- Mounts the specified Backblaze B2 bucket to `/home/ubuntu/Backblaze` with optimized settings.
- Applies persistent PRAGMA settings to the SQLite database to optimize for remote access.
- Moves the Pastel data file (`data001.sqlite3`) to the Backblaze B2 bucket if it doesn't already exist there.
- Creates a symbolic link from the original location to the new location on the Backblaze B2 bucket.
- Adds a crontab entry to remount the Backblaze B2 bucket at reboot.

## Notes

- Ensure that the specified bucket exists in your Backblaze B2 account.
- Ensure that the Pastel data file exists at the specified location before running the script.
- Handle the script with care, as it contains sensitive credentials.
- The optimized settings in the script are tailored to reduce network latency, enhance caching, and improve concurrent access. Adjustments might be necessary based on actual workload and network conditions.

## Performance Optimizations and Rationale

The script employs several performance tweaks to facilitate efficient access to the SQLite database hosted on a remote Backblaze B2 bucket. The main challenge addressed by these optimizations is the network latency inherent in accessing remote storage. Here's a breakdown of the key optimizations:

1. **Rclone Mount Options**:
   - `--vfs-cache-mode full`: Full cache mode caches file structure, content, and writes. This helps in reducing the latency of reading and writing data to the remote storage.
   - `--vfs-cache-max-age 3h`: This sets the maximum age for objects in the cache, allowing frequently accessed files to be retrieved from the cache instead of the remote storage.
   - `--vfs-cache-max-size 20G`: This increases the size of the cache, allowing more files to be cached.
   - `--buffer-size 64M`: Increasing the buffer size can enhance read and write performance by buffering more data locally.
   - `--multi-thread-streams 4`: Enabling multi-threading for file streams improves concurrent read/write operations.

2. **SQLite PRAGMA Options**:
   - `PRAGMA page_size = 65536`: Max page size of 64KB reduces the number of network requests by reading more data at once.
   - `PRAGMA journal_mode = WAL`: Write-Ahead Logging allows reads and writes to proceed concurrently, mitigating latency.
   - `PRAGMA synchronous = NORMAL`: Reducing the synchronous level improves write performance but with a trade-off in durability.
   - `PRAGMA cache_size = -524288`: Increasing the cache size to 512MB reduces reads from remote storage, minimizing latency.
   - `PRAGMA busy_timeout = 5000`: A 5-second busy timeout helps with contention issues due to network latency.
   - `PRAGMA wal_autocheckpoint = 1000`: Fine-tuning the autocheckpoint frequency helps manage the WAL file size.

3. **Handling Existing Files and Symbolic Links**:
   - The script checks for the existence of the destination file and symbolic link to prevent overwriting or duplicating them.
   - The use of symbolic links ensures that the application can access the remote file as if it were local.

4. **Environment Variables for Credentials**:
   - The script accepts Backblaze B2 credentials as environment variables, enhancing security and flexibility.

5. **VACUUM Command**:
   - The `VACUUM` command is used to rebuild the database file, ensuring that the page size change takes effect. It's only called if the page size is being altered.

These optimizations are tailored to address the specific challenges of accessing an SQLite database hosted on remote cloud storage. They aim to minimize the impact of network latency, improve concurrent access, and ensure that the remote file is accessed transparently by the application. Adjustments to these settings might be necessary based on the actual workload, network conditions, and available local storage.

## Screenshot of Script

![Screenshot](screenshot.svg)
