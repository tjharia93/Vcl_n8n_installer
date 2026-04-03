# How To Use Guide

Step-by-step instructions for installing, operating, and maintaining your VCL n8n instance.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Accessing n8n](#accessing-n8n)
- [Daily Operations](#daily-operations)
- [Backup and Restore](#backup-and-restore)
- [Updating n8n](#updating-n8n)
- [Managing Workflows](#managing-workflows)
- [Viewing Logs](#viewing-logs)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)

---

## Prerequisites

Before you begin, make sure you have:

1. **A fresh Ubuntu server** (22.04 LTS or 24.04 LTS)
2. **A user with sudo access** (do not run as root)
3. **Internet connectivity**
4. **At least 5 GB of free disk space**

Optional items to have ready:

- OpenAI API key (if your workflows use AI)
- Zoho IMAP email and app password (if using Zoho email integration)
- URL of your companion workflow repo (Repo 2)

---

## Installation

### Step 1: Clone the installer

```bash
git clone https://github.com/your-org/vcl-n8n-ubuntu-installer.git
cd vcl-n8n-ubuntu-installer
```

### Step 2: Make the installer executable

```bash
chmod +x install.sh
```

### Step 3: Run the installer

```bash
./install.sh
```

### Step 4: Answer the prompts

The installer will ask you a series of questions:

```
Install mode:
  1. Test (SQLite, relaxed settings)
  2. Production (PostgreSQL, recommended)
Choose [2]:
```

Press Enter to accept the default (shown in brackets), or type your choice.

**Prompt walkthrough:**

| Prompt | Default | Notes |
|---|---|---|
| Install mode | Production | Test mode uses SQLite automatically |
| Database | PostgreSQL | Recommended for production |
| n8n host/IP | localhost | Use your server's IP for remote access |
| n8n port | 5678 | Change if port is already in use |
| Timezone | Africa/Nairobi | Use your local timezone |
| Admin username | admin | n8n login username |
| Admin password | (none) | Required, not shown as you type |
| OpenAI API key | (skip) | Press Enter to skip |
| Zoho IMAP email | (skip) | Press Enter to skip |
| Zoho IMAP password | (skip) | Only asked if email is provided |
| Alert email | (skip) | Press Enter to skip |
| Repo 2 URL | (skip) | Press Enter to skip |

### Step 5: Wait for completion

The installer will:
1. Install Docker (if needed)
2. Create the folder structure
3. Generate your configuration files
4. Start the n8n stack
5. Verify n8n is running
6. Clone and import workflows (if Repo 2 URL provided)

You will see progress indicators like `[1/10] Pre-checks passed.` for each step.

### Step 6: Verify

Once complete, you will see:

```
============================================
  Installation complete!
============================================

  n8n is running at: http://localhost:5678
  Config:   /opt/vcl/config/
  Data:     /opt/vcl/runtime/
  Apps:     /opt/vcl/apps/
```

---

## Accessing n8n

Open your browser and go to:

```
http://<your-server-ip>:5678
```

Log in with the admin username and password you set during installation.

If you used `localhost` as the host and are accessing from a different machine, you will need to use the server's actual IP address or hostname instead.

---

## Daily Operations

### Check the status of your installation

```bash
./scripts/show_status.sh
```

This shows:
- Whether containers are running
- Whether n8n is reachable
- Disk usage for data directories

### Stop n8n

```bash
cd /opt/vcl/config
docker compose stop
```

### Start n8n

```bash
cd /opt/vcl/config
docker compose start
```

### Restart n8n

```bash
cd /opt/vcl/config
docker compose restart
```

### Stop and remove containers (without losing data)

```bash
cd /opt/vcl/config
docker compose down
```

Your data in `/opt/vcl/runtime/` is preserved. Run `docker compose up -d` to start again.

---

## Backup and Restore

### Create a backup

```bash
./scripts/backup_n8n.sh
```

This creates a timestamped archive at `/opt/vcl/runtime/backups/vcl_backup_YYYYMMDD_HHMMSS.tar.gz` containing:
- Your `.env` and `docker-compose.yml`
- n8n data
- PostgreSQL data (if applicable)

**Recommendation:** Run backups regularly, especially before updating.

### List existing backups

```bash
ls -lh /opt/vcl/runtime/backups/
```

### Restore from a backup

```bash
./scripts/restore_n8n.sh /opt/vcl/runtime/backups/vcl_backup_20260101_120000.tar.gz
```

This will:
1. Ask for confirmation
2. Stop the running stack
3. Extract the backup over the existing files
4. Restart the stack

---

## Updating n8n

### Update to the latest stable version

```bash
./update.sh
```

This pulls the latest `n8nio/n8n:stable` image and restarts the stack. Your data and configuration are preserved.

**Before updating:**
1. Run a backup: `./scripts/backup_n8n.sh`
2. Check the [n8n release notes](https://docs.n8n.io/release-notes/) for breaking changes

### Check which version is running

```bash
docker exec vcl-n8n n8n --version
```

---

## Managing Workflows

### Import workflows from Repo 2

If you skipped Repo 2 during installation, or want to re-import:

```bash
# Clone the repo (if not already done)
git clone <your-repo-2-url> /opt/vcl/apps/vcl-email-automation

# Copy workflows into the container and import
docker exec vcl-n8n sh -c "mkdir -p /tmp/workflows"
docker cp /opt/vcl/apps/vcl-email-automation/workflows/. vcl-n8n:/tmp/workflows/
docker exec vcl-n8n n8n import:workflow --separate --input=/tmp/workflows
docker exec vcl-n8n sh -c "rm -rf /tmp/workflows"
```

**Warning:** Importing workflows with the same IDs as existing ones will overwrite them.

### Export all workflows

```bash
./scripts/export_workflows.sh
```

Saves all workflows to a timestamped JSON file in `/opt/vcl/runtime/files/exports/`.

### Export a single workflow

```bash
docker exec vcl-n8n n8n export:workflow --id=<workflow-id> --output=/tmp/workflow.json
docker cp vcl-n8n:/tmp/workflow.json ./my_workflow.json
```

### Update workflows from Repo 2

```bash
cd /opt/vcl/apps/vcl-email-automation
git pull

# Re-import
docker exec vcl-n8n sh -c "mkdir -p /tmp/workflows"
docker cp /opt/vcl/apps/vcl-email-automation/workflows/. vcl-n8n:/tmp/workflows/
docker exec vcl-n8n n8n import:workflow --separate --input=/tmp/workflows
docker exec vcl-n8n sh -c "rm -rf /tmp/workflows"
```

---

## Viewing Logs

### View all container logs

```bash
cd /opt/vcl/config
docker compose logs
```

### Follow logs in real time

```bash
cd /opt/vcl/config
docker compose logs -f
```

### View only n8n logs

```bash
docker logs vcl-n8n
```

### View only PostgreSQL logs

```bash
docker logs vcl-postgres
```

### View last 100 lines

```bash
docker logs --tail 100 vcl-n8n
```

---

## Troubleshooting

### n8n is not reachable after installation

**Check if containers are running:**
```bash
cd /opt/vcl/config
docker compose ps
```

If the n8n container shows as "restarting" or "exited", check logs:
```bash
docker logs vcl-n8n
```

**Common causes:**
- Port already in use: Change `N8N_PORT` in `/opt/vcl/config/.env` and restart
- PostgreSQL not ready: The compose file includes a health check, but on very slow machines the timeout may be too short. Restart the stack: `docker compose restart`

### "Permission denied" errors

```bash
./scripts/reset_permissions.sh
```

Then restart:
```bash
cd /opt/vcl/config
docker compose restart
```

### Database connection errors

If n8n cannot connect to PostgreSQL:

1. Check that the postgres container is running: `docker ps | grep vcl-postgres`
2. Check postgres logs: `docker logs vcl-postgres`
3. Verify the password matches between the `DB_POSTGRESDB_PASSWORD` and `POSTGRES_PASSWORD` lines in `/opt/vcl/config/.env`

### Container keeps restarting

Check logs for the error:
```bash
docker logs --tail 50 vcl-n8n
```

Common causes:
- Invalid environment variable values
- Corrupt n8n data directory
- Out of disk space: Check with `df -h`

### Forgot admin password

Edit `/opt/vcl/config/.env` and change `N8N_BASIC_AUTH_PASSWORD`, then restart:
```bash
cd /opt/vcl/config
docker compose restart
```

### Docker permission errors

If you see "permission denied" when running docker commands:
```bash
sudo usermod -aG docker $USER
```

Log out and log back in for the group change to take effect.

### Port conflict

If port 5678 is already in use:

1. Edit `/opt/vcl/config/.env` and change `N8N_PORT` to another port (e.g., `5679`)
2. Restart: `cd /opt/vcl/config && docker compose down && docker compose up -d`

### Disk space is running low

Check what is using space:
```bash
du -sh /opt/vcl/runtime/*
```

Clean up old backups:
```bash
ls -lh /opt/vcl/runtime/backups/
rm /opt/vcl/runtime/backups/vcl_backup_<old_date>.tar.gz
```

Clean up Docker:
```bash
docker system prune -f
```

---

## Uninstalling

### Remove the n8n stack but keep data

```bash
./uninstall.sh
```

Choose "N" when asked to remove data. Your configuration and runtime data remain at `/opt/vcl/`.

### Remove everything

```bash
./uninstall.sh
```

Choose "y" when asked to remove data. This deletes all of `/opt/vcl/` including:
- Configuration files
- n8n data
- PostgreSQL data
- Backups
- Cloned app repos

**This is irreversible.** Make a backup first if you want to preserve anything.

### Remove Docker (optional)

If you no longer need Docker on this machine:

```bash
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd
```
