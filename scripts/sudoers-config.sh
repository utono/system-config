#!/usr/bin/env bash

# Purpose: Sync sudoers.d configurations
# Usage: ./sync_sudoers.sh <utono_directory_path>

set -euo pipefail

sync_sudoers() {
    local utono_path="$1"

    if [ ! -d "$utono_path" ]; then
        echo "The specified directory does not exist: $utono_path"
        exit 1
    fi

    if [ -d "${utono_path}/system-config/sudoers.d/etc/sudoers.d/" ]; then
        sudo rsync -av --chown=root:root "${utono_path}/system-config/sudoers.d/etc/sudoers.d/" /etc/sudoers.d/
        sudo chmod 440 /etc/sudoers.d/*
        echo "sudoers.d configurations synced successfully."
    else
        echo "Source directory for sudoers.d does not exist. Skipping."
    fi
}

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <utono_directory_path>"
    exit 1
fi

sync_sudoers "$1"
