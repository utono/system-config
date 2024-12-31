#!/usr/bin/env bash

# This script configures a system to blacklist NVIDIA drivers and removes NVIDIA-related udev rules.
# It is typically run when:
# 1. Transitioning from using NVIDIA graphics to open-source drivers (like Nouveau) or other hardware drivers.
# 2. Preparing the system to prevent NVIDIA drivers from loading during boot.
# 3. Applying custom configurations for NVIDIA driver blacklisting and removal rules.

# **Important Notes:**
# - The script must be run as root because it modifies system-level configuration files in `/etc`.
# - The user must provide the path to a directory (`utono_directory_path`) containing the configuration files:
#   - `blacklist-nvidia.conf` (to blacklist NVIDIA modules via modprobe).
#   - `00-remove-nvidia.rules` (udev rules to manage NVIDIA device handling).
# - If the specified directory doesn't exist or the configuration files are not found, the script will fail to copy them.

# **When to Run:**
# - After ensuring no essential NVIDIA-dependent applications are in use.
# - Before rebooting into a configuration without NVIDIA drivers.
# - As part of a setup or deployment process that involves system reconfiguration.

# **Script Behavior:**
# - Copies `blacklist-nvidia.conf` to `/etc/modprobe.d/`.
# - Copies `00-remove-nvidia.rules` to `/etc/udev/rules.d/`.
# - Logs successful file synchronizations and reports failed commands for debugging purposes.
# - Provides clear feedback on successful execution or errors.

# Usage: sudo ./blacklist_nvidia.sh <utono_directory_path>
# Example: sudo ./blacklist_nvidia.sh /path/to/config/directory

set -uo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

FAILED_COMMANDS=()
RSYNC_LOG=()

log_rsync() {
    local src="$1"
    local dest="$2"
    RSYNC_LOG+=("Synced: $src -> $dest")
}

configure_nvidia_blacklist_and_removal() {
    local utono_path="$1"

    rsync -av --chown=root:root "${utono_path}/system-configs/modprobe.d/etc/modprobe.d/blacklist-nvidia.conf" /etc/modprobe.d/ && \
        log_rsync "${utono_path}/system-configs/modprobe.d/etc/modprobe.d/blacklist-nvidia.conf" "/etc/modprobe.d/" || \
        FAILED_COMMANDS+=("rsync blacklist-nvidia.conf")

    rsync -av --chown=root:root "${utono_path}/system-configs/udev/etc/udev/rules.d/00-remove-nvidia.rules" /etc/udev/rules.d/ && \
        log_rsync "${utono_path}/system-configs/udev/etc/udev/rules.d/00-remove-nvidia.rules" "/etc/udev/rules.d/" || \
        FAILED_COMMANDS+=("rsync udev rules")
}

main() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <utono_directory_path>"
        exit 1
    fi

    local utono_path="$1"
    configure_nvidia_blacklist_and_removal "$utono_path"

    echo "NVIDIA blacklist and removal configuration applied successfully."
}

main "$@"
