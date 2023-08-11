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
- You can either modify the script to directly include your Backblaze credentials, or store them in the environment variables `B2_APP_KEY_ID` and `B2_APP_KEY` (strongly recommended), in which case you can run the script without modification.
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

### Utilizing Local Backblaze Region URL with Cloudflare for Enhanced Performance

Backblaze B2 has different region URLs corresponding to the physical locations of their data centers. By using the URL of the region closest to your location, and leveraging Cloudflare's network, you can dramatically enhance the speed and reliability of accessing your remote SQLite database.

Here's a step-by-step guide to help you set up and configure this:

1. **Determine Your Local Backblaze Region URL**: Log into your Backblaze B2 dashboard and browse your files. Click on the metadata for any file, and you'll find a share link that contains the local region URL. For someone on the US east coast, for example, the region URL might be `f002.backblazeb2.com`.

2. **Purchase a Domain**: Choose a domain registrar that offers affordable domains (e.g., Namecheap, GoDaddy, Google Domains) and purchase a domain that suits your needs.

3. **Create a Cloudflare Account**: Sign up for a free account on [Cloudflare](https://www.cloudflare.com/).

4. **Add Your Domain to Cloudflare**: 
   - Click on "Add a Site" in your Cloudflare dashboard.
   - Enter your domain name and click "Add Site."
   - Select the Free plan, and follow the instructions to update your domain's nameservers with the ones provided by Cloudflare.

5. **Configure Cloudflare for Backblaze B2**: 
   - Go back to Cloudflare, click on "DNS," and add a CNAME record with your domain pointing to the Backblaze B2 local region URL.
   - Make sure the proxy status (orange cloud) is enabled for this CNAME record.

6. **Update the Script with Your Domain**: Modify the rclone mount command in the script to use your domain with the `--b2-endpoint` option. For example:

   ```bash
   rclone mount myb2bucket:"$BUCKET_NAME" "$MOUNT_POINT" \
     --b2-endpoint https://yourdomain.com \
     ...
   ```

7. **Verify the Setup**: Test the connection to ensure that everything is working as expected.

By following these steps, you'll take advantage of the local Backblaze B2 region and Cloudflare's global network. This setup can dramatically enhance the speed and reliability of accessing your remote SQLite database, especially when network latency is a concern.

Keep in mind that while Cloudflare's services are often free, there may be costs associated with purchasing a domain and other specific configurations. Always consult the respective documentation and support channels of the services you're using for the most accurate and up-to-date information.

## Screenshot of Script

![Screenshot](screenshot.svg)
