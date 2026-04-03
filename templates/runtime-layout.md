# Runtime Layout

The installer creates this structure on the target Ubuntu machine:

```
/opt/vcl/
├── installer/                  # Installer repo (this project)
│   └── vcl-n8n-ubuntu-installer/
├── apps/                       # Application repos
│   └── vcl-email-automation/   # Repo 2 (workflows + automation logic)
├── runtime/                    # All runtime/persistent data
│   ├── n8n_data/               # n8n internal data (~/.n8n)
│   ├── postgres_data/          # PostgreSQL data directory
│   ├── backups/                # Backup archives
│   ├── logs/                   # Application logs
│   └── files/                  # File processing directories
│       ├── inbox_files/        # Incoming files (e.g., email attachments)
│       ├── processed/          # Successfully processed files
│       ├── review/             # Files flagged for manual review
│       ├── failed/             # Files that failed processing
│       └── exports/            # Export output
└── config/                     # Active configuration
    ├── .env                    # Environment variables (secrets)
    └── docker-compose.yml      # Active compose file
```

## Design Principles

- **Config** is separate from **runtime data** and **app logic**
- **Secrets** live only in `/opt/vcl/config/.env` (chmod 600)
- **Runtime data** is all under `/opt/vcl/runtime/` for easy backup
- **App repos** are cloned into `/opt/vcl/apps/` and are replaceable
