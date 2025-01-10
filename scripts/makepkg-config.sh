#!/usr/bin/env bash

# Purpose: Modify makepkg.conf for optimal build settings
# Usage: ./modify_makepkg.sh

set -euo pipefail

configure_makepkg_settings() {
    local makepkg_conf="/etc/makepkg.conf"
    local backup_conf="${makepkg_conf}.bak.$(date +%Y%m%d%H%M%S)"

    # Prompt for sudo password at the beginning
    if ! sudo -v; then
        echo "Sudo access is required to run this script. Exiting."
        exit 1
    fi

    # Create a backup of the current makepkg.conf
    sudo cp "$makepkg_conf" "$backup_conf"

    # Update MAKEFLAGS for parallel jobs
    sudo sed -i "s/-j2/-j$(nproc)/" "$makepkg_conf"

    # Uncomment MAKEFLAGS if commented
    sudo sed -i "/^#MAKEFLAGS/s/^#//" "$makepkg_conf"

    echo "makepkg.conf updated successfully."
}

configure_makepkg_settings
