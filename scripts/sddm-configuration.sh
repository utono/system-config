#!/usr/bin/env bash

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Function to sync the Xsetup file
sync_xsetup_file() {
    local utono_path="$1"
    local src="${utono_path}/system-configs/sddm/usr/share/sddm/scripts/Xsetup"
    local dest="/usr/share/sddm/scripts/Xsetup"

    # Backup the existing Xsetup file if it exists
    if [[ -f "$dest" ]]; then
        echo "Backing up existing Xsetup file to ${dest}.bak..."
        cp "$dest" "${dest}.bak"
    fi

    # Copy the custom Xsetup file
    if [[ -f "$src" ]]; then
        echo "Copying custom Xsetup configuration..."
        rsync -av "$src" "$dest"
    else
        echo "Source Xsetup file not found at $src. Exiting."
        exit 1
    fi

    # Display any xrandr commands in the Xsetup file
    echo "Checking for xrandr commands in $dest..."
    grep -E "xrandr" "$dest" || echo "No xrandr commands found in $dest."
}

# Main function
main() {
    if [[ "$#" -ne 1 ]]; then
        echo "Usage: $0 <utono_directory_path>"
        exit 1
    fi

    local utono_path="$1"
    sync_xsetup_file "$utono_path"
    echo "SDDM configuration updated successfully."
}

# Execute the main function
main "$@"
