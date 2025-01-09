#!/usr/bin/env bash

# Purpose: Configure various system settings for Arch Linux, including pacman, sudoers, and makepkg.
# Usage: ./system-configuration.sh <utono_directory_path>
# Requires: Sudo access, rsync, and chattr commands.

set -uo pipefail

# Prompt for sudo password at the beginning
if ! sudo -v; then
    echo "Sudo access is required to run this script. Exiting."
    exit 1
fi

# Ensure required commands are available
if ! command -v rsync &> /dev/null || ! command -v chattr &> /dev/null; then
    echo "Required commands (rsync, chattr) are missing. Install them and re-run the script."
    exit 1
fi

# Arrays to track failed commands and rsync operations
FAILED_COMMANDS=()
RSYNC_LOG=()

# Function to log rsync operations
log_rsync() {
    local src="$1"
    local dest="$2"
    RSYNC_LOG+=("Synced: $src -> $dest")
}

# Function to update pacman.conf
update_pacman_config() {
    local pacman_conf="/etc/pacman.conf"
    local backup_conf="${pacman_conf}.bak"

    # Create a backup of the current pacman.conf
    if [[ -f $pacman_conf ]]; then
        sudo cp -v "$pacman_conf" "$backup_conf"
    fi

    # Define additions and edits
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

# Function to sync sudoers.d configurations
sync_sudoers() {
    local utono_path="$1"

    if [ -d "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" ]; then
        sudo rsync -av --chown=root:root "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" /etc/sudoers.d/ && \
            log_rsync "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" "/etc/sudoers.d/" || FAILED_COMMANDS+=("rsync sudoers.d")
        sudo chmod 440 /etc/sudoers.d/* || FAILED_COMMANDS+=("chmod 440 sudoers.d")
    else
        echo "[SKIPPED] Source directory for sudoers.d does not exist."
    fi
}

# Function to configure makepkg settings
configure_makepkg_settings() {
    local makepkg_conf="/etc/makepkg.conf"
    sudo cp "$makepkg_conf" "${makepkg_conf}.bak.$(date +%Y%m%d%H%M%S)" || FAILED_COMMANDS+=("backup makepkg.conf")
    sudo sed -i "s/-j2/-j$(nproc)/" "$makepkg_conf" || FAILED_COMMANDS+=("sed update makepkg.conf")
    sudo sed -i "/^#MAKEFLAGS/s/^#//" "$makepkg_conf" || FAILED_COMMANDS+=("uncomment MAKEFLAGS")
}

# Report rsync operations
report_rsync_operations() {
    if [ ${#RSYNC_LOG[@]} -eq 0 ]; then
        echo "No rsync operations were performed."
    else
        echo "Rsync operations performed:"
        for operation in "${RSYNC_LOG[@]}"; do
            echo "- $operation"
        done
    fi
}

# Report any failures
report_failures() {
    if [ ${#FAILED_COMMANDS[@]} -ne 0 ]; then
        echo "The following commands failed:"
        for cmd in "${FAILED_COMMANDS[@]}"; do
            echo "- $cmd"
        done
        exit 1
    else
        echo "All commands completed successfully."
    fi
}

# Main script logic
main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <utono_directory_path>"
        exit 1
    fi

    local utono_path="$1"

    update_pacman_config
    sync_sudoers "$utono_path"
    # configure_makepkg_settings  # Uncomment if makepkg settings need adjustment
    report_rsync_operations
    report_failures
}

main "$@"
