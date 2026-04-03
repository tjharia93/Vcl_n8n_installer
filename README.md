# VCL n8n Ubuntu Installer

Automated installer for self-hosted [n8n](https://n8n.io) on Ubuntu using Docker Compose.

Takes a fresh Ubuntu machine and sets up a complete n8n environment with PostgreSQL, environment-based configuration, and optional workflow import from a companion automation repo.

## What It Does

- Validates the target system (Ubuntu version, sudo, disk space, internet)
- Installs Docker CE and the Docker Compose plugin
- Creates a clean runtime folder structure at `/opt/vcl/`
- Collects configuration through an interactive prompt
- Generates `.env` and `docker-compose.yml` from your inputs
- Starts the n8n stack and confirms it is healthy
- Optionally clones a companion app repo and imports its workflows

## Quick Start

```bash
git clone https://github.com/your-org/vcl-n8n-ubuntu-installer.git
cd vcl-n8n-ubuntu-installer
chmod +x install.sh
./install.sh
```

The installer walks you through everything. No manual config editing needed.

## Requirements

- Ubuntu 22.04 LTS or 24.04 LTS
- sudo access
- Internet connection
- At least 5 GB free disk space

## Documentation

| Document | Description |
|---|---|
| [TECHNICAL.md](TECHNICAL.md) | Architecture, file structure, environment variables, Docker setup, bootstrap pipeline, and design decisions |
| [HOWTO.md](HOWTO.md) | Step-by-step guides for installation, daily operations, backup/restore, updating, troubleshooting, and uninstall |

## V1 Scope

This version covers:

- Ubuntu only
- Docker Compose deployment
- n8n with PostgreSQL (recommended) or SQLite
- Interactive `.env` generation
- Companion repo clone and workflow import
- Backup, restore, update, and status utilities

Not yet included (planned for v2):

- Reverse proxy / HTTPS
- Queue mode
- Multi-node deployment
