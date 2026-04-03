# VCL n8n Ubuntu Installer

Automated installer for self-hosted [n8n](https://n8n.io) on Ubuntu using Docker Compose, with PostgreSQL as the recommended database and optional workflow import from a companion app repo.

## Purpose

Takes a fresh Ubuntu machine and performs the full base setup for self-hosted n8n:

- System pre-checks and dependency installation
- Docker and Docker Compose plugin installation
- Runtime folder structure creation
- Interactive configuration and `.env` generation
- `docker-compose.yml` generation (PostgreSQL or SQLite)
- n8n stack startup with health checks
- Optional cloning of a companion workflow repo (Repo 2)
- Optional workflow import into n8n

## Supported Ubuntu Versions

- Ubuntu 22.04 LTS (Jammy)
- Ubuntu 24.04 LTS (Noble)

## What Gets Installed

- Docker CE
- Docker Compose plugin
- n8n (Docker image: `n8nio/n8n:stable`)
- PostgreSQL 16 (Docker image, if selected)

## Quick Start

```bash
git clone https://github.com/your-org/vcl-n8n-ubuntu-installer.git
cd vcl-n8n-ubuntu-installer
chmod +x install.sh
./install.sh
```

The installer will prompt you for configuration values (database choice, credentials, API keys, etc.) and handle everything else automatically.

## Folder Layout on Target Machine

After installation, the following structure is created:

```
/opt/vcl/
├── installer/          # This repo (cloned here or symlinked)
├── apps/               # Companion app repos (Repo 2, etc.)
│   └── vcl-email-automation/
├── runtime/
│   ├── n8n_data/       # n8n persistent data
│   ├── postgres_data/  # PostgreSQL data (if using Postgres)
│   ├── backups/        # Backup archives
│   ├── logs/           # Application logs
│   └── files/          # File processing directories
│       ├── inbox_files/
│       ├── processed/
│       ├── review/
│       ├── failed/
│       └── exports/
└── config/
    ├── .env            # Generated environment variables
    └── docker-compose.yml
```

## SQLite vs PostgreSQL

| Feature | SQLite | PostgreSQL |
|---|---|---|
| Setup complexity | Simpler | Slightly more |
| Performance at scale | Limited | Strong |
| Concurrent access | Single-writer | Full concurrency |
| Recommended for | Testing | Production |

PostgreSQL is the recommended default. SQLite is available for quick test installs.

## How Repo 2 Is Used

During installation, you can provide a URL for a companion automation repo (Repo 2). The installer will:

1. Clone it into `/opt/vcl/apps/vcl-email-automation/`
2. Look for workflow JSON files in the `workflows/` directory
3. Import them into n8n using the n8n CLI (`n8n import:workflow`)

**Note:** Workflow import can overwrite existing workflows if IDs match. The initial import on a fresh install is safe.

## Update

```bash
cd /path/to/vcl-n8n-ubuntu-installer
./update.sh
```

This pulls the latest n8n image and restarts the stack.

## Backup

```bash
./scripts/backup_n8n.sh
```

Creates a timestamped backup of n8n data, database, and configuration in `/opt/vcl/runtime/backups/`.

## Uninstall

```bash
./uninstall.sh
```

Stops containers and removes the Docker stack. Optionally removes all data under `/opt/vcl/`.

## Repo Structure

```
vcl-n8n-ubuntu-installer/
├── README.md
├── .gitignore
├── install.sh              # Main entry point
├── uninstall.sh            # Teardown script
├── update.sh               # Update n8n to latest
├── bootstrap/              # Numbered install steps
│   ├── 01_precheck.sh
│   ├── 02_install_docker.sh
│   ├── 03_create_structure.sh
│   ├── 04_collect_inputs.sh
│   ├── 05_generate_env.sh
│   ├── 06_generate_compose.sh
│   ├── 07_start_stack.sh
│   ├── 08_healthcheck.sh
│   ├── 09_clone_apps.sh
│   └── 10_import_workflows.sh
├── templates/              # Compose and env templates
│   ├── .env.example
│   ├── docker-compose.postgres.yml
│   ├── docker-compose.sqlite.yml
│   └── runtime-layout.md
├── scripts/                # Utility scripts
│   ├── backup_n8n.sh
│   ├── restore_n8n.sh
│   ├── export_workflows.sh
│   ├── show_status.sh
│   └── reset_permissions.sh
└── config/
    └── installer.defaults
```

## V1 Scope

This version focuses on:

- Ubuntu only
- Docker Compose only
- n8n + PostgreSQL (SQLite available)
- `.env` generation from user input
- Repo 2 clone and workflow import
- No reverse proxy / HTTPS (planned for v2)
- No queue mode (planned for v2)
