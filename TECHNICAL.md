# Technical Documentation

Detailed technical reference for the VCL n8n Ubuntu Installer.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repo Structure](#repo-structure)
- [Target Machine Layout](#target-machine-layout)
- [Bootstrap Pipeline](#bootstrap-pipeline)
- [Environment Variables](#environment-variables)
- [Docker Compose Templates](#docker-compose-templates)
- [Database Options](#database-options)
- [Workflow Import](#workflow-import)
- [Utility Scripts](#utility-scripts)
- [Security Considerations](#security-considerations)
- [Design Decisions](#design-decisions)

---

## Architecture Overview

The installer follows a modular pipeline design. The top-level `install.sh` is a thin orchestrator that calls 10 numbered bootstrap scripts in sequence. Each script handles one responsibility and exits on failure, halting the pipeline.

```
install.sh
  -> 01_precheck.sh       (validate system)
  -> 02_install_docker.sh  (install Docker + Compose)
  -> 03_create_structure.sh(create /opt/vcl/ tree)
  -> 04_collect_inputs.sh  (interactive prompts)
  -> 05_generate_env.sh    (write .env from answers)
  -> 06_generate_compose.sh(copy correct template)
  -> 07_start_stack.sh     (docker compose up)
  -> 08_healthcheck.sh     (verify n8n responds)
  -> 09_clone_apps.sh      (clone companion repo)
  -> 10_import_workflows.sh(import workflow JSON)
```

Inter-script communication uses a temporary file at `/tmp/vcl_installer_answers.env`, which stores the user's answers from step 04. Steps 05 through 10 source this file as needed. The temp file is created with `chmod 600` since it contains secrets.

---

## Repo Structure

```
vcl-n8n-ubuntu-installer/
├── README.md                   # Project overview and quick start
├── TECHNICAL.md                # This file
├── HOWTO.md                    # User-facing guides
├── .gitignore
│
├── install.sh                  # Main entry point
├── uninstall.sh                # Stop stack, optionally remove data
├── update.sh                   # Pull latest images, restart
│
├── bootstrap/                  # Numbered install pipeline
│   ├── 01_precheck.sh          # System validation
│   ├── 02_install_docker.sh    # Docker CE + Compose plugin
│   ├── 03_create_structure.sh  # Create /opt/vcl/ directory tree
│   ├── 04_collect_inputs.sh    # Interactive user prompts
│   ├── 05_generate_env.sh      # Write /opt/vcl/config/.env
│   ├── 06_generate_compose.sh  # Copy compose template to config
│   ├── 07_start_stack.sh       # docker compose up -d
│   ├── 08_healthcheck.sh       # HTTP check with retries
│   ├── 09_clone_apps.sh        # Clone Repo 2 into /opt/vcl/apps/
│   └── 10_import_workflows.sh  # Import workflow JSON via n8n CLI
│
├── templates/                  # Static templates
│   ├── .env.example            # Reference .env with placeholder values
│   ├── docker-compose.postgres.yml
│   ├── docker-compose.sqlite.yml
│   └── runtime-layout.md       # Visual reference for /opt/vcl/
│
├── scripts/                    # Post-install utilities
│   ├── backup_n8n.sh           # Archive data + config
│   ├── restore_n8n.sh          # Restore from backup archive
│   ├── export_workflows.sh     # Export workflows to JSON
│   ├── show_status.sh          # Container status + disk usage
│   └── reset_permissions.sh    # Fix /opt/vcl/ ownership
│
└── config/
    └── installer.defaults      # Default prompt values
```

---

## Target Machine Layout

The installer creates this structure on the Ubuntu host:

```
/opt/vcl/
├── installer/                  # Installer repo
│   └── vcl-n8n-ubuntu-installer/
├── apps/                       # Companion application repos
│   └── vcl-email-automation/   # Repo 2 (cloned in step 09)
│       └── workflows/          # Workflow JSON files (imported in step 10)
├── runtime/                    # All persistent/runtime data
│   ├── n8n_data/               # Mounted as /home/node/.n8n in container
│   ├── postgres_data/          # Mounted as PostgreSQL data directory
│   ├── backups/                # Timestamped backup archives
│   ├── logs/                   # Application logs
│   └── files/                  # File processing directories
│       ├── inbox_files/        # Incoming files (email attachments, etc.)
│       ├── processed/          # Successfully processed
│       ├── review/             # Flagged for manual review
│       ├── failed/             # Failed processing
│       └── exports/            # Exported data
└── config/                     # Active configuration
    ├── .env                    # Environment variables (chmod 600)
    └── docker-compose.yml      # Active compose file
```

**Design principle:** Config, runtime data, and application logic are separated. Backing up `/opt/vcl/runtime/` and `/opt/vcl/config/` captures all stateful data. App repos under `/opt/vcl/apps/` can be re-cloned at any time.

---

## Bootstrap Pipeline

### 01_precheck.sh

Validates the target system before anything is installed:

| Check | Requirement | Behavior on failure |
|---|---|---|
| OS | Ubuntu | Exit with error |
| Version | 22.04 or 24.04 | Warning + confirm prompt for other versions |
| sudo | Available | Exit with error |
| Internet | Can reach `https://get.docker.com` | Exit with error |
| curl | Installed | Auto-installs via apt |
| git | Installed | Auto-installs via apt |
| Disk space | >= 5 GB free on `/` | Exit with error |

### 02_install_docker.sh

Installs Docker CE and the Docker Compose plugin using Docker's official apt repository. Skips entirely if both `docker` and `docker compose` are already available. Adds the current user to the `docker` group.

### 03_create_structure.sh

Creates the full `/opt/vcl/` directory tree and sets ownership to `$USER:$USER`.

### 04_collect_inputs.sh

Interactive prompt that collects:

- Install mode (test / production)
- Database choice (SQLite / PostgreSQL)
- n8n host, port, timezone
- Admin username and password
- OpenAI API key (optional)
- Zoho IMAP credentials (optional)
- Alert email address (optional)
- Repo 2 URL (optional)

In test mode, database automatically defaults to SQLite.

Answers are written to `/tmp/vcl_installer_answers.env` (chmod 600).

### 05_generate_env.sh

Reads the collected answers and generates `/opt/vcl/config/.env`. Auto-generates:

- `N8N_ENCRYPTION_KEY` (64-character hex via `openssl rand`)
- `DB_POSTGRESDB_PASSWORD` (32-character hex, only for PostgreSQL)

The `.env` file is set to `chmod 600`.

### 06_generate_compose.sh

Copies the appropriate template (`docker-compose.postgres.yml` or `docker-compose.sqlite.yml`) to `/opt/vcl/config/docker-compose.yml`.

### 07_start_stack.sh

Runs `docker compose up -d` from `/opt/vcl/config/`.

### 08_healthcheck.sh

Attempts to reach n8n via HTTP with up to 6 retries at 5-second intervals (30 seconds total). Does not exit with an error on failure, since first startup can take longer due to image pulls and database migration.

### 09_clone_apps.sh

Clones Repo 2 into `/opt/vcl/apps/vcl-email-automation/`. If the directory already exists with a `.git` folder, it runs `git pull` instead. Skips if no Repo 2 URL was provided.

### 10_import_workflows.sh

Looks for `*.json` files in `/opt/vcl/apps/vcl-email-automation/workflows/`. If found:

1. Creates `/tmp/workflows/` inside the n8n container
2. Copies workflow files into the container via `docker cp`
3. Runs `n8n import:workflow --separate --input=/tmp/workflows`
4. Cleans up the temp directory inside the container

Skips if no workflow directory or no JSON files exist.

**Warning:** n8n's import can overwrite workflows with matching IDs. This is safe on a fresh install but should be used carefully on existing instances.

---

## Environment Variables

The generated `.env` file contains all configuration for both n8n and PostgreSQL containers.

### Core n8n Settings

| Variable | Default | Purpose |
|---|---|---|
| `N8N_HOST` | `localhost` | Host n8n binds to |
| `N8N_PORT` | `5678` | Port exposed on host |
| `N8N_PROTOCOL` | `http` | Protocol (http/https) |
| `GENERIC_TIMEZONE` | `Africa/Nairobi` | n8n internal timezone |
| `TZ` | `Africa/Nairobi` | Container timezone |

### Security

| Variable | Default | Purpose |
|---|---|---|
| `N8N_BASIC_AUTH_ACTIVE` | `true` | Enable basic auth |
| `N8N_BASIC_AUTH_USER` | `admin` | Admin username |
| `N8N_BASIC_AUTH_PASSWORD` | (user-provided) | Admin password |
| `N8N_ENCRYPTION_KEY` | (auto-generated) | Encrypts credentials stored in DB |

### Binary Data

| Variable | Default | Purpose |
|---|---|---|
| `N8N_DEFAULT_BINARY_DATA_MODE` | `filesystem` | Store binary data on disk instead of memory |

n8n defaults to in-memory binary data, which can cause crashes with large files (email attachments, etc.). Filesystem mode writes binary data to the n8n data directory. Note: filesystem mode is not compatible with queue mode.

### PostgreSQL (when selected)

| Variable | Default | Purpose |
|---|---|---|
| `DB_TYPE` | `postgresdb` | Database driver |
| `DB_POSTGRESDB_HOST` | `postgres` | Docker service name |
| `DB_POSTGRESDB_PORT` | `5432` | PostgreSQL port |
| `DB_POSTGRESDB_DATABASE` | `n8n` | Database name |
| `DB_POSTGRESDB_USER` | `n8n` | Database user |
| `DB_POSTGRESDB_PASSWORD` | (auto-generated) | Database password |
| `POSTGRES_DB` | `n8n` | Used by postgres image for init |
| `POSTGRES_USER` | `n8n` | Used by postgres image for init |
| `POSTGRES_PASSWORD` | (auto-generated) | Used by postgres image for init |

### Integration Credentials

| Variable | Purpose |
|---|---|
| `OPENAI_API_KEY` | OpenAI API access for AI-powered workflows |
| `ZOHO_IMAP_HOST` | Zoho mail server (`imap.zoho.com`) |
| `ZOHO_IMAP_PORT` | IMAP port (`993`) |
| `ZOHO_IMAP_USER` | Zoho email address |
| `ZOHO_IMAP_PASSWORD` | Zoho app password |
| `ZOHO_IMAP_SSL` | Enable SSL (`true`) |
| `ALERT_EMAIL_TO` | Recipient for alert notifications |

---

## Docker Compose Templates

### PostgreSQL Template (`docker-compose.postgres.yml`)

Defines two services:

**postgres:**
- Image: `postgres:16`
- Container name: `vcl-postgres`
- Reads credentials from `.env` via `env_file`
- Data persisted to `/opt/vcl/runtime/postgres_data`
- Includes a health check using `pg_isready`

**n8n:**
- Image: `n8nio/n8n:stable`
- Container name: `vcl-n8n`
- Depends on postgres with `condition: service_healthy` (waits for DB readiness)
- Exposes `N8N_PORT` on the host
- Reads all config from `.env` via `env_file`
- n8n data persisted to `/opt/vcl/runtime/n8n_data`
- File processing directory mounted at `/files`

### SQLite Template (`docker-compose.sqlite.yml`)

Single n8n service only. Same volume mounts and port configuration. No database container needed since n8n creates an SQLite database inside its data directory.

---

## Database Options

### PostgreSQL (Recommended)

- Production-grade relational database
- Full concurrent access support
- Better performance with many workflows and executions
- Runs as a separate Docker container
- Data stored at `/opt/vcl/runtime/postgres_data`
- Health check ensures n8n doesn't start before DB is ready

### SQLite

- n8n's built-in default when no database is configured
- Zero additional setup
- Single-file database inside n8n data directory
- Suitable for testing and low-volume use
- No separate container needed

---

## Workflow Import

The installer uses n8n's built-in CLI for workflow management:

- **Import:** `n8n import:workflow --separate --input=<directory>`
  - `--separate` treats each JSON file as an individual workflow
  - Files must be valid n8n workflow JSON exports
  - Workflows with matching IDs will be overwritten

- **Export (via utility script):** `n8n export:workflow --all --output=<file>`
  - Exports all workflows to a single JSON file

Workflow files are expected in the companion repo at:
```
vcl-email-automation/workflows/*.json
```

---

## Utility Scripts

All scripts are in the `scripts/` directory.

### backup_n8n.sh

Creates a timestamped `.tar.gz` archive containing:
- `/opt/vcl/config/.env`
- `/opt/vcl/config/docker-compose.yml`
- `/opt/vcl/runtime/n8n_data/`
- `/opt/vcl/runtime/postgres_data/` (if present)

Also exports workflows from the running n8n instance before archiving. Backups are saved to `/opt/vcl/runtime/backups/`.

### restore_n8n.sh

Takes a backup archive path as argument. Stops the stack, extracts the archive over `/opt/vcl/`, and restarts. Prompts for confirmation before overwriting.

### export_workflows.sh

Exports all workflows from the running n8n instance to a timestamped JSON file in `/opt/vcl/runtime/files/exports/`.

### show_status.sh

Displays:
- Docker Compose container status
- n8n reachability (HTTP check)
- Disk usage for runtime directories

### reset_permissions.sh

Resets ownership of `/opt/vcl/` to `$USER:$USER` and ensures `.env` is `chmod 600`. Useful after manual file operations or container permission issues.

---

## Security Considerations

### Secrets Management

- `.env` is generated with `chmod 600` (owner-only read/write)
- `.env` is in `.gitignore` and is never committed
- `N8N_ENCRYPTION_KEY` is auto-generated (64-character hex)
- PostgreSQL password is auto-generated (32-character hex)
- Temporary answer file (`/tmp/vcl_installer_answers.env`) is also `chmod 600`

### Network Exposure

- n8n is exposed on the configured port with no TLS termination in v1
- No reverse proxy is configured (planned for v2)
- For production use, place behind a reverse proxy (nginx, Caddy, Traefik) with HTTPS

### Container Isolation

- Containers run with Docker's default isolation
- n8n runs as the `node` user inside its container
- PostgreSQL runs as the `postgres` user inside its container
- Host volumes are owned by the installing user

### n8n Environment Variables with _FILE Suffix

n8n supports `_FILE` variants for secret environment variables (e.g., `DB_POSTGRESDB_PASSWORD_FILE`), which read the secret from a file instead of the environment. This is useful for Docker secrets integration but is not used in v1 for simplicity.

---

## Design Decisions

### Why Docker Compose

n8n officially documents Docker Compose as the recommended deployment method for Linux servers. It provides a reproducible, isolated environment that can be started, stopped, and updated with simple commands.

### Why PostgreSQL as Default

While n8n defaults to SQLite when unconfigured, PostgreSQL provides better concurrent access, performance at scale, and is the standard choice for production self-hosted n8n deployments.

### Why Filesystem Binary Data Mode

n8n stores binary data (file attachments, API responses with binary content) in memory by default. For workflows that handle email attachments or file processing, this can cause out-of-memory crashes. Setting `N8N_DEFAULT_BINARY_DATA_MODE=filesystem` writes binary data to disk instead.

### Why Numbered Bootstrap Scripts

Numbered scripts provide:
- Clear execution order
- Single-responsibility per script
- Easy debugging (re-run a specific step)
- Simple progress tracking (`[N/10]` output)

### Why /opt/vcl/ as the Root

`/opt/` is the standard Linux location for optional application software. Using a dedicated `/opt/vcl/` namespace avoids conflicts with other software and keeps all project files in a predictable location.

### Why Temp File for Inter-Script Communication

Using `/tmp/vcl_installer_answers.env` allows each bootstrap script to remain independent (no function imports or shared shell state). Any script can be re-run by sourcing the answers file.
