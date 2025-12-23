#!/bin/bash
# Conditional wrapper for Proxmox installation
# Only runs if INSTALL_PROXMOX environment variable is set to "true"

if [ "${INSTALL_PROXMOX}" = "true" ]; then
    echo "Installing Proxmox VE..."
    exec "$(dirname "$0")/install-proxmox.sh"
else
    echo "Skipping Proxmox installation (INSTALL_PROXMOX != true)"
    exit 0
fi
