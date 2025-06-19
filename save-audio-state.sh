#!/usr/bin/env bash

# Save current audio configuration and firmware status for future troubleshooting.
# Run with: ./save-audio-state.sh ~/audio-logs/2025-06-18-audio.txt

outfile="$1"

if [[ -z "$outfile" ]]; then
  echo "Usage: $0 <output-file-path>"
  exit 1
fi

mkdir -p "$(dirname "$outfile")"

{
  echo "===================== System Info ====================="
  uname -a
  echo
  pacman -Q linux linux-firmware sof-firmware || true

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
  sudo lspci | grep -i audio

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

echo "✅ Saved audio state to: $outfile"
