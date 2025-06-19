#!/usr/bin/env bash

# ~/utono/system-config/save-audio-state.sh
#
# 📋 Save your system's current audio state to a log file.
#
# Usage:
#   ~/utono/system-config/save-audio-state.sh ~/audio-logs/YYYY-MM-DD-audio.txt
#
# Example:
#   ~/utono/system-config/save-audio-state.sh ~/audio-logs/2025-06-18-audio.txt
#
# This script gathers kernel, firmware, audio devices, and service info
# for future debugging in case audio stops working.

outfile="$1"

if [[ -z "$outfile" ]]; then
  echo "❌ Usage: $0 <output-log-file-path>"
  exit 1
fi

mkdir -p "$(dirname "$outfile")"

{
  echo "===================== System Info ====================="
  uname -a
  echo
  pacman -Q linux linux-firmware sof-firmware 2>/dev/null || true

  echo
  echo "===================== pactl Info ====================="
  pactl info
  echo
  pactl list short sinks

  echo
  echo "===================== aplay Devices ====================="
  aplay -l

  echo
  echo "===================== ALSA PCI Audio ====================="
  lspci | grep -i audio

  echo
  echo "===================== PipeWire Services ====================="
  systemctl --user status pipewire pipewire-pulse wireplumber

  echo
  echo "===================== dmesg: audio ====================="
  sudo dmesg | grep -i audio

  echo
  echo "===================== dmesg: firmware ====================="
  sudo dmesg | grep -i firmware

} | tee "$outfile"

echo "✅ Audio state saved to: $outfile"
