#!/usr/bin/env bash

# ~/utono/system-config/setup-xps-17-9700-audio.sh
#
# Sets up SOF + SoundWire audio support on Dell XPS 17 9700.
# Downloads UCM2 profile archive if missing and applies it.
# Also reinstalls necessary firmware and restarts the audio stack.

set -euo pipefail

UCM_URL="https://bbs.archlinux.org/profile.php?id=173653&attach=sof-soundwire.zip"
UCM_ZIP="$HOME/Downloads/sof-soundwire.zip"
UCM_DIR="/usr/share/alsa/ucm2"
UCM_DEST="$UCM_DIR/sof-soundwire"

echo "🎧 Installing required packages..."
sudo pacman -S --needed sof-firmware alsa-ucm-conf pipewire-alsa

echo "📦 Checking for UCM2 profile archive..."
if [[ ! -f "$UCM_ZIP" ]]; then
  echo "🌐 Downloading sof-soundwire.zip from Arch forum..."
  curl -L --retry 3 -o "$UCM_ZIP" "$UCM_URL" || {
    echo "❌ Failed to download: $UCM_URL"
    exit 1
  }
  echo "✅ Downloaded: $UCM_ZIP"
else
  echo "✅ Found local UCM2 archive: $UCM_ZIP"
fi

echo "🧩 Installing custom UCM2 profiles..."
sudo mkdir -p "$UCM_DIR"
[[ -d "$UCM_DEST" ]] && sudo mv -v "$UCM_DEST" "${UCM_DEST}.bak.$(date +%s)" || true
sudo unzip -o "$UCM_ZIP" -d "$UCM_DIR"

echo "🔁 Restarting PipeWire and WirePlumber..."
systemctl --user restart pipewire pipewire-pulse wireplumber

echo "✅ Setup complete. Please reboot and run:"
echo "  pactl list short sinks"
echo "You may also need to unmute outputs in alsamixer."
