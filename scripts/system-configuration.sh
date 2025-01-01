#!/usr/bin/env bash

# This script automates the synchronization and configuration of system files 
# and settings for an Arch Linux system. It performs the following tasks:
# 1. Syncs dotfiles from a specified source directory to the appropriate locations.
# 2. Updates the pacman configuration file with backups of existing configurations.
# 3. Syncs sudoers.d configurations and ensures the correct file permissions.
# 4. Configures makepkg settings to optimize build performance.
# 5. Logs all rsync operations and reports any failed commands.
#
# Usage:
#   sudo ./script_name.sh <utono_directory_path>
# Replace <utono_directory_path> with the absolute path to the directory containing
# the source files for synchronization and configuration.
#
# Requirements:
# - Must be run as root.
# - Dependencies: rsync, chattr
#
# Any errors encountered during execution will be logged and reported at the end.

set -uo pipefail

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
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

# Function to sync dotfiles
sync_dotfiles() {
    local utono_path="$1"

    # if [ -d "${utono_path}/tty-dotfiles" ]; then
        # rsync -av --chown=root:root "${utono_path}/tty-dotfiles" /root/ && log_rsync "${utono_path}/tty-dotfiles" "/root/" || FAILED_COMMANDS+=("rsync tty-dotfiles")
    # fi

    mkdir -p "$HOME/.config/nvim" || FAILED_COMMANDS+=("mkdir ~/.config/nvim")
    rsync -av --chown=root:root "${utono_path}/kickstart-modular.nvim/" "$HOME/.config/nvim/" && log_rsync "${utono_path}/kickstart-modular.nvim/" "$HOME/.config/nvim/" || FAILED_COMMANDS+=("rsync kickstart-modular.nvim")
    mkdir -p "$HOME/.local/bin" || FAILED_COMMANDS+=("mkdir ~/.local/bin")
}

# Function to sync pacman.conf
# sync_pacman_config() {
#     local utono_path="$1"
#
#     if [ -f "${utono_path}/aiso/mkarchiso/releng-custom/custom/airootfs/etc/pacman.conf" ]; then
#         rsync -av --chown=root:root --backup --suffix=.bak "${utono_path}/aiso/mkarchiso/releng-custom/custom/airootfs/etc/pacman.conf" /etc/ && \
#         log_rsync "${utono_path}/aiso/mkarchiso/releng-custom/custom/airootfs/etc/pacman.conf" "/etc/" || \
#         FAILED_COMMANDS+=("rsync pacman.conf")
#     else
#         echo "[SKIPPED] pacman.conf source file does not exist."
#     fi
# }

# Function to update pacman.conf
update_pacman_config() {
    local pacman_conf="/etc/pacman.conf"
    local backup_conf="${pacman_conf}.bak"

    # Create a backup of the current pacman.conf
    if [[ -f $pacman_conf ]]; then
        cp -v "$pacman_conf" "$backup_conf"
    fi

    # Define additions and edits
    local additions=(
        "[archlive_aur_repository]\nSigLevel = Optional TrustAll\nServer = file:///root/utono/archlive_aur_repository\n"
        # "[heftig]\nSigLevel = Optional\nServer = https://pkgbuild.com/~heftig/repo/\$arch\n"
    )

    # Ensure 'ILoveCandy' and 'ParallelDownloads = 10' exist in the [options] section
    # sed -i '/^\[options\]/a ILoveCandy\nParallelDownloads = 10' "$pacman_conf"

    # Append repository configurations if not already present
    for addition in "${additions[@]}"; do
        if ! grep -Fxq "$(echo -e "$addition" | head -n1)" "$pacman_conf"; then
            echo -e "\n$addition" >> "$pacman_conf"
        fi
    done

    echo "pacman.conf updated successfully."
}

# Function to sync sudoers.d configurations
sync_sudoers() {
    local utono_path="$1"

    if [ -d "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" ]; then
        rsync -av --chown=root:root "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" /etc/sudoers.d/ && log_rsync "${utono_path}/system-configs/sudoers.d/etc/sudoers.d/" "/etc/sudoers.d/" || FAILED_COMMANDS+=("rsync sudoers.d")
        chmod 440 /etc/sudoers.d/* || FAILED_COMMANDS+=("chmod 440 sudoers.d")
    else
        echo "[SKIPPED] Source directory for sudoers.d does not exist."
    fi
}

# Function to configure makepkg settings
configure_makepkg_settings() {
    cp /etc/makepkg.conf "/etc/makepkg.conf.bak.$(date +%Y%m%d%H%M%S)" || FAILED_COMMANDS+=("backup makepkg.conf")
    sed -i "s/-j2/-j$(nproc)/" /etc/makepkg.conf || FAILED_COMMANDS+=("sed update makepkg.conf")
    sed -i "/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf || FAILED_COMMANDS+=("uncomment MAKEFLAGS")
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

    sync_dotfiles "$utono_path"
    # sync_pacman_config "$utono_path"
    update_pacman_config
    sync_sudoers "$utono_path"
    # configure_makepkg_settings
    report_rsync_operations
    report_failures
}

main "$@"
