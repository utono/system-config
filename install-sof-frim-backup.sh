#!/usr/bin/env bash

# install-sof-from-backup.sh
#
# Installs known-good SOF firmware files from backup.
# Validates them against a firmware.sha256 file unless --generate or --undo is used.

set -euo pipefail

BACKUP_DIR="$HOME/utono/system-config/firmware-known-good"
SOF_RI="$BACKUP_DIR/sof-cml.ri"
SOF_TPLG="$BACKUP_DIR/sof-cml-rt711-rt1308-rt715.tplg"
SHA_FILE="$BACKUP_DIR/firmware.sha256"

TARGET_RI="/usr/lib/firmware/intel/sof/sof-cml.ri"
TARGET_TPLG="/usr/lib/firmware/intel/sof-tplg/sof-cml-rt711-rt1308-rt715.tplg"

MODE="${1:-}"

# --generate: create a sha256 reference
if [[ "$MODE" == "--generate" ]]; then
  echo "🧾 Generating SHA256 checksum file..."
  sha256sum "$SOF_RI" "$SOF_TPLG" > "$SHA_FILE"
  echo "✅ Saved to: $SHA_FILE"
  exit 0
fi

# --undo: remove installed firmware
if [[ "$MODE" == "--undo" ]]; then
  echo "🧹 Removing manually installed SOF firmware..."
  sudo chattr -i "$TARGET_RI" "$TARGET_TPLG" 2>/dev/null || true
  sudo rm -v "$TARGET_RI" "$TARGET_TPLG"
  echo "✅ Firmware files removed."
  exit 0
fi

# Validate presence
if [[ ! -f "$SOF_RI" || ! -f "$SOF_TPLG" ]]; then
  echo "❌ Backup firmware files not found in: $BACKUP_DIR"
  exit 1
fi

# Validate hash if available
if [[ -f "$SHA_FILE" ]]; then
  echo "🔍 Validating backup files against: $SHA_FILE"
  if ! (cd "$BACKUP_DIR" && sha256sum --quiet --check "$(basename "$SHA_FILE")"); then
    echo "⚠️ WARNING: One or more firmware files do not match the known-good checksum."
    exit 1
  fi
  echo "✅ Checksum validation passed."
else
  echo "ℹ️ No checksum file found. Skipping validation."
fi

# Install
echo "🔧 Installing SOF firmware from backup..."
sudo chattr -i "$TARGET_RI" "$TARGET_TPLG" 2>/dev/null || true
sudo install -Dm644 "$SOF_RI" "$TARGET_RI"
sudo install -Dm644 "$SOF_TPLG" "$TARGET_TPLG"
sudo chattr +i "$TARGET_RI" "$TARGET_TPLG" 2>/dev/null || echo "(chattr not supported – skipped)"

echo "✅ Firmware restored from backup."
echo "🔁 Reboot to apply changes."
