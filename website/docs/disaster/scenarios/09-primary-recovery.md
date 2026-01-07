---
sidebar_position: 9
title: 'Scenario 9: Family Emergency Recovery Guide'
---

# Scenario 9: Family Emergency Recovery Guide

**For: Non-technical family members**

**Purpose: Access family photos and important files from backups**

If something has happened to me and you need to access our family photos, videos, or important documents, this guide
will walk you through the process step-by-step. Don't worry - you don't need to be technical to follow these
instructions.

## What You Need

Before you start, gather these items:

1. **A computer** - Any Windows, Mac, or Linux computer will work
2. **Internet connection** - For downloading files from cloud storage
3. **Bitwarden password manager access**
   - You should have the master password written down in the safe
   - If not, check the emergency contact information at the end of this guide

## Step-by-Step Recovery Instructions

### Part 1: Get Your Passwords (5 minutes)

All passwords are stored securely in Bitwarden. Here's how to access them:

#### Option A: If you already have Bitwarden installed

1. Open the Bitwarden app on your computer or phone
2. Log in with:
   - **Email**: (written in the safe or emergency documents)
   - **Master Password**: (written in the safe or emergency documents)
3. Once logged in, search for "B2" or "Backblaze"
4. You'll see the login information for our backup storage
5. Write down (or keep Bitwarden open):
   - Application Key ID
   - Application Key

#### Option B: If you need to install Bitwarden

1. Go to [https://bitwarden.com](https://bitwarden.com)
2. Click "Get Started" or "Download"
3. Download the desktop app for your computer (Windows/Mac)
4. Install it by double-clicking the downloaded file
5. Open Bitwarden
6. Click "Log In"
7. Enter:
   - **Email**: (from emergency documents)
   - **Master Password**: (from emergency documents)
8. Search for "B2" or "Backblaze"
9. Copy the Application Key ID and Application Key

**Screenshot description**: The Bitwarden login screen would show email and master password fields with a blue "Log in
with master password" button.

### Part 2: Access TrueNAS (Local Network Storage) (10 minutes)

If you're on the home network, you can access files directly from the local storage:

1. Open a web browser (Chrome, Firefox, or Safari)
2. Type in the address bar: `http://truenas.local` or `http://192.168.1.10`
   - (The exact address should be in the emergency documents)
3. You'll see a login screen
4. Log in with:

   - **Username**: Look in Bitwarden for "TrueNAS"
   - **Password**: Also in Bitwarden under "TrueNAS"

5. Once logged in:

   - Click "Storage" in the left menu
   - Click "Pools"
   - Find the pool named "data" or "family"
   - Click the three dots (...) next to it
   - Select "Browse" or "View Files"

6. Navigate to the folder you need:

   - Family photos are usually in: `/mnt/data/photos/` or `/photos/`
   - Videos: `/mnt/data/videos/` or `/videos/`
   - Documents: `/mnt/data/documents/` or `/documents/`

7. To download files:
   - Check the boxes next to files you want
   - Click "Download" button
   - Files will download to your Downloads folder

**Note**: This only works if the home server is still running. If not, proceed to Part 3 for cloud backups.

### Part 3: Download from Cloud Backup (Backblaze B2) (20 minutes)

All important files are automatically backed up to Backblaze B2 cloud storage. Here's how to download them:

#### Step 1: Install Cyberduck (File Download Program)

1. Go to [https://cyberduck.io](https://cyberduck.io)
2. Click the large "Download" button
3. Choose your operating system:
   - Windows: Download and run the .exe file
   - Mac: Download and open the .dmg file
4. Install Cyberduck by following the on-screen prompts
5. Open Cyberduck when installation is complete

**Screenshot description**: Cyberduck's website shows a clean interface with a large download button and a duck icon.

#### Step 2: Connect to Backblaze B2

1. In Cyberduck, click "Open Connection" (at the top left)

2. In the dropdown at the top of the window, select "Backblaze B2"

   - If you don't see it, type "B2" in the search box

3. Fill in the connection details:

   - **Application Key ID**: (from Bitwarden, the one you copied earlier)
   - **Application Key**: (from Bitwarden)
   - Leave other fields as default

4. Click "Connect"

5. You should now see a list of "buckets" (folders). Look for:
   - `homelab-velero-b2` - Contains server backups
   - `homelab-cnpg-b2` - Contains database backups
   - `family-photos-b2` - Contains family photos (if this bucket exists)
   - Or any bucket with "backup" in the name

**Screenshot description**: The Cyberduck connection window shows dropdown menu for "Backblaze B2", fields for
Application Key ID and Application Key, and a blue Connect button.

#### Step 3: Download Your Files

**For family photos and documents:**

1. Double-click on the bucket that contains your files

   - Usually `homelab-velero-b2` or a bucket named with "photos" or "family"

2. Navigate through folders to find what you need:

   - Photos are often in folders by year: `2024/`, `2023/`, etc.
   - Or by category: `family-photos/`, `vacation/`, etc.

3. To download:

   - **Single file**: Right-click the file → Select "Download To..." → Choose where to save
   - **Whole folder**: Right-click the folder → Select "Download To..." → Choose where to save
   - **Multiple files**: Hold Ctrl (Windows) or Cmd (Mac) and click files → Right-click → "Download To..."

4. Be patient - large files and folders take time to download

**For Velero backups (advanced - contains server data):**

The `homelab-velero-b2` bucket contains complete backups of the home server. These are technical backups, but may
contain recent files:

1. Open `homelab-velero-b2` bucket
2. Look for folders with dates in the name, like `daily-20241227-020000`
   - Format is: `type-YYYYMMDD-HHMMSS`
   - Choose the most recent date
3. Inside, you'll find compressed backup files (`.tar.gz` files)
4. Download these if you need to preserve the complete server state
5. **Note**: Extracting these requires technical knowledge - contact technical help (see end of guide)

### Part 4: What to Download (Priority Order)

If you're not sure what to download, here's a recommended priority:

#### Highest Priority (Download First)

- [ ] **Family photos** - Usually the most important and irreplaceable
  - Look for folders named: `photos/`, `Pictures/`, or organized by year
- [ ] **Family videos** - Also irreplaceable
  - Look for: `videos/`, `Movies/`, or by event names
- [ ] **Important documents**
  - Look for: `documents/`, `scans/`, `legal/`, `financial/`

#### Medium Priority

- [ ] **Personal files**
  - Look for: `home/`, user folders, `Desktop/`, `Documents/`
- [ ] **Music collection** (if important to you)
  - Look for: `music/`, `audio/`

#### Lower Priority (Can be re-downloaded/recreated)

- [ ] Server configurations
- [ ] Application data
- [ ] System backups

### Part 5: Alternative Method - Use Backblaze Web Interface

If Cyberduck doesn't work, you can use the Backblaze website:

1. Go to [https://www.backblaze.com/b2/sign-in.html](https://www.backblaze.com/b2/sign-in.html)

2. Log in with:

   - **Email**: (from Bitwarden - search for "Backblaze account")
   - **Password**: (also in Bitwarden under Backblaze account)
   - **Note**: This is different from the Application Key used in Cyberduck

3. Once logged in:

   - Click "Buckets" in the left menu
   - Click on the bucket name you want to access
   - Click "Browse Files"

4. Navigate to files:

   - Click folder names to open them
   - Click file names to see details

5. To download:
   - Click the file name
   - Click "Download" button
   - **Note**: You can only download one file at a time this way
   - For multiple files, use Cyberduck (Part 3)

**Screenshot description**: The Backblaze B2 web interface shows a list of buckets with names, file counts, and sizes. A
"Browse Files" button appears next to each bucket.

## Understanding File Backups

Our backup system creates multiple copies of files automatically:

### Backup Schedule

- **Hourly**: Every hour during the day (kept for 48 hours)
- **Daily**: Every night at 2 AM (kept for 30 days)
- **Weekly**: Every Sunday (kept for 12 weeks)
- **Monthly**: First Sunday of each month (kept for 12 months)

### What This Means

- If you need a file from yesterday, use the daily backup
- If you need a file from last month, use the weekly or monthly backup
- Older monthly backups go back up to a year

### Finding the Right Backup Date

Backups are named with dates. Here's how to read them:

- `daily-20241227-020000` means:
  - Type: daily backup
  - Date: December 27, 2024 (2024-12-27)
  - Time: 02:00:00 (2 AM)

Choose the backup closest to when the file you need was last okay.

## Troubleshooting Common Issues

### "Access Denied" or "Authentication Failed"

**Problem**: Wrong password or Application Key

**Solution**:

1. Go back to Bitwarden
2. Make sure you copied the entire Application Key ID and Application Key
3. There should be no extra spaces at the beginning or end
4. Try copying again or typing it carefully
5. Check if Caps Lock is on - passwords are case-sensitive

### "Cannot Connect to Server"

**Problem**: Internet connection or wrong server address

**Solution**:

1. Check your internet connection - try opening a website
2. For TrueNAS: Make sure you're on the home network (not cellular or public WiFi)
3. For Backblaze B2: Make sure you selected "Backblaze B2" in the connection type
4. Try closing and reopening Cyberduck

### "Bucket is Empty" or "No Files Found"

**Problem**: Looking in wrong location

**Solution**:

1. Try a different bucket - there may be multiple backup locations
2. Look inside folders - files may be organized in subfolders
3. Check bucket names carefully - they might be similar

### Download is Very Slow

**Problem**: Large files or slow internet

**Solution**:

1. This is normal for large photo/video collections
2. Download smaller folders at a time instead of everything at once
3. Let it run overnight for very large downloads
4. If it times out, restart the download - it should resume where it left off

### Don't Know Which Backup Date to Use

**Problem**: Multiple backups available

**Solution**:

1. If you just need the most recent version: Use the newest backup (highest date number)
2. If you need a file that was deleted recently: Try backups from before it was deleted
3. If unsure: Download a few different backup dates to compare

## What Each Backup Contains

### homelab-velero-b2 Bucket

**Contains**: Complete server backups including all files and configurations **Size**: Usually very large (tens to
hundreds of GB) **Format**: Technical backup format (requires technical knowledge to extract) **Use when**: You need
complete server recovery or technical assistance

### homelab-cnpg-b2 Bucket

**Contains**: Database backups (technical data from applications) **Size**: Medium (depends on data) **Format**:
PostgreSQL database files (requires technical knowledge) **Use when**: Technical assistance needed to restore
application data

### Other Buckets

If there are buckets with names like:

- `family-photos`: Direct photo storage
- `documents`: Direct document storage
- `media`: Videos and music

These are easier to access - files are stored normally and can be downloaded directly.

## Important: What to Save

After downloading files from backups:

1. **Save to an external hard drive**

   - Buy a large external USB hard drive (2TB or more)
   - Copy all downloaded files to it
   - Keep it in a safe place

2. **Save to another cloud service** (for extra safety)

   - Google Drive: [https://drive.google.com](https://drive.google.com)
   - Dropbox: [https://www.dropbox.com](https://www.dropbox.com)
   - Microsoft OneDrive: [https://onedrive.com](https://onedrive.com)
   - Upload important photos and documents

3. **Keep the Backblaze B2 account active**
   - The backups will stay there as long as the account is paid
   - Payment information should be in Bitwarden
   - Consider keeping it active for at least a year

## Emergency Contacts for Technical Help

If you get stuck or need help, contact these people:

### Primary Technical Contact

**Name**: (Your trusted tech-savvy friend/family member) **Phone**: **Email**: **What they can help with**: Accessing
backups, downloading files, general tech support

### Backblaze Support

**Phone**: 1-650-352-3738 (US) **Email**: help@backblaze.com **Website**:
[https://help.backblaze.com](https://help.backblaze.com) **Hours**: 8am-5pm Pacific Time, Monday-Friday **What they can
help with**: Accessing B2 account, downloading files, account issues

### Local IT Professional

**Name**: (Your local computer repair shop) **Phone**: **Address**: **What they can help with**: Can help with
downloading files, extracting technical backups, data recovery

## Advanced: For Technical Family Members

If you have technical knowledge or are working with an IT professional, here's additional information:

### Complete Infrastructure Recovery

The homelab uses:

- **Talos Linux**: Kubernetes operating system
- **Velero**: Kubernetes backup tool
- **CNPG**: PostgreSQL database operator
- **ArgoCD**: GitOps deployment tool
- **OpenTofu**: Infrastructure as code

### GitHub Repository

All configuration is stored in git:

- **Repository**: https://github.com/theepicsaxguy/homelab
- **Access**: Credentials in Bitwarden (search "GitHub")
- Contains complete infrastructure definition

### Recovery Process

1. **For disk failure recovery**: See [Scenario 2: Disk Failure](02-disk-failure.md)
2. **For specific applications**: See [Scenario 1: Accidental Deletion](01-accidental-deletion.md)
3. **For ransomware/security**: See [Scenario 6: Ransomware Attack](06-ransomware.md)

### Velero Restore Commands

If you have kubectl access to a Kubernetes cluster:

```bash
# List available backups
velero backup get --storage-location backblaze-b2

# Restore specific namespace
velero restore create family-recovery \
  --from-backup daily-YYYYMMDD-020000 \
  --include-namespaces <namespace> \
  --storage-location backblaze-b2
```

### CNPG Database Recovery

If you need to restore databases:

```bash
# List backups
kubectl -n <namespace> exec -it <cluster-name>-1 -- \
  barman-cloud-backup-list \
  --endpoint-url https://s3.us-west-002.backblazeb2.com \
  s3://homelab-cnpg-b2/<namespace>/<cluster-name>

# See Scenario 1 or 8 for complete recovery procedures
```

### B2 CLI Access

For command-line access to B2:

```bash
# Install B2 CLI
pip install b2

# Authenticate
b2 authorize-account <application-key-id> <application-key>

# List buckets
b2 list-buckets

# Download entire bucket
b2 sync b2://homelab-velero-b2 /local/backup/path
```

## Keeping This Information Updated

**For whoever maintains this documentation:**

Please update this guide if:

- [ ] Backup locations change
- [ ] Emergency contacts change
- [ ] Bitwarden master password is reset
- [ ] New backup buckets are created
- [ ] File locations are reorganized
- [ ] Better recovery tools become available

**Last updated**: (add date when creating this document)

**Last tested**: (date when last verified that recovery process works)

## Additional Resources

### Backup Documentation

- Main disaster recovery guide: [Disaster Recovery Overview](../disaster-recovery.md)
- All recovery scenarios: [Scenarios Index](../disaster-recovery.md#scenarios)

### Video Tutorials (if created)

- (Link to any video guides you've created)
- (YouTube channel with how-to videos)

### Written Instructions Elsewhere

- Physical copy location: (e.g., "Safe deposit box", "Home safe")
- Digital copy location: (e.g., "USB drive in desk", "Printed and filed")

## Summary Checklist

To recover your files, you need to:

- [ ] Get Bitwarden master password (from safe/emergency documents)
- [ ] Access Bitwarden to get B2 credentials
- [ ] Install Cyberduck on your computer
- [ ] Connect to Backblaze B2 with credentials
- [ ] Find the bucket with your files
- [ ] Download important files (photos, videos, documents)
- [ ] Save downloads to external hard drive
- [ ] Consider uploading to additional cloud service for safety
- [ ] Keep Backblaze B2 account paid and active

## Remember

- **Take your time** - These files aren't going anywhere
- **Don't panic** - Everything is backed up in multiple places
- **Ask for help** - Contact the people listed above if you get stuck
- **Download important files first** - Prioritize photos and documents
- **Save to multiple places** - External drive AND cloud storage
- **Keep backups active** - Don't cancel the Backblaze account

Your family memories and important documents are safe in these backups. Following this guide step-by-step will help you
recover everything you need.

---

**Note to maintainer**: Print this guide and keep a copy with emergency documents. Update contact information and
credentials locations as needed.
