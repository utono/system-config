#!/usr/bin/env bash

# Purpose: Add repositories to pacman.conf
# Usage: ./add_repositories.sh

set -euo pipefail

update_pacman_config() {
    local pacman_conf="/etc/pacman.conf"
    local backup_conf="${pacman_conf}.bak"

    # Prompt for sudo password at the beginning
    if ! sudo -v; then
        echo "Sudo access is required to run this script. Exiting."
        exit 1
    fi

    # Create a backup of the current pacman.conf
    if [[ -f $pacman_conf ]]; then
        sudo cp -v "$pacman_conf" "$backup_conf"
    fi

    # Define repository additions
    local additions=(
        "[archlive_aur_repository]\nSigLevel = Optional TrustAll\nServer = file:///root/utono/archlive_aur_repository\n"
    )

    # Append repository configurations if not already present
    for addition in "${additions[@]}"; do
        if ! grep -Fxq "$(echo -e "$addition" | head -n1)" "$pacman_conf"; then
            echo -e "\n$addition" | sudo tee -a "$pacman_conf" > /dev/null
        fi
    done

    echo "pacman.conf updated successfully."
}

update_pacman_config
