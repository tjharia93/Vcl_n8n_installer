#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  VCL n8n Ubuntu Installer"
echo "============================================"
echo ""

bash "$SCRIPT_DIR/bootstrap/01_precheck.sh"
bash "$SCRIPT_DIR/bootstrap/02_install_docker.sh"
bash "$SCRIPT_DIR/bootstrap/03_create_structure.sh"
bash "$SCRIPT_DIR/bootstrap/04_collect_inputs.sh"
bash "$SCRIPT_DIR/bootstrap/05_generate_env.sh"        "$SCRIPT_DIR"
bash "$SCRIPT_DIR/bootstrap/06_generate_compose.sh"     "$SCRIPT_DIR"
bash "$SCRIPT_DIR/bootstrap/07_start_stack.sh"
bash "$SCRIPT_DIR/bootstrap/08_healthcheck.sh"
bash "$SCRIPT_DIR/bootstrap/09_clone_apps.sh"
bash "$SCRIPT_DIR/bootstrap/10_import_workflows.sh"

echo ""
echo "============================================"
echo "  Installation complete!"
echo "============================================"
echo ""
echo "  n8n is running at: http://$(grep N8N_HOST /opt/vcl/config/.env | cut -d= -f2):$(grep N8N_PORT /opt/vcl/config/.env | cut -d= -f2)"
echo "  Config:   /opt/vcl/config/"
echo "  Data:     /opt/vcl/runtime/"
echo "  Apps:     /opt/vcl/apps/"
echo ""
