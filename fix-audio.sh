#!/usr/bin/env bash

# ~/utono/system-config/fix-audio.sh
#
# Hard reset PipeWire + WirePlumber audio stack by stopping socket units.
# Verifies that real sinks are restored. Uses mako to notify result.

set -euo pipefail

notify() {
  makoctl dismiss --all &>/dev/null || true
  notify-send "🎧 fix-audio.sh" "$1"
}

echo "🔧 Stopping PipeWire services and sockets..."
systemctl --user stop pipewire.service pipewire.socket pipewire-pulse.service pipewire-pulse.socket wireplumber.service || true

echo "🔪 Killing stray pipewire processes..."
pkill -x pipewire || true
pkill -x pipewire-pulse || true
pkill -x wireplumber || true

echo "🧹 Removing WirePlumber state..."
rm -rf ~/.local/state/wireplumber

echo "🚀 Starting services fresh..."
systemctl --user start pipewire.socket pipewire-pulse.socket wireplumber.service

echo "⏳ Waiting for sinks to register..."
sleep 4

sinks=$(pactl list short sinks | grep -v auto_null || true)

if [[ -n "$sinks" ]]; then
  echo "✅ Real sinks restored:"
  echo "$sinks"
  notify "✅ Audio fixed: real sinks are available."
else
  echo "❌ Still only auto_null."
  pactl list short sinks
  notify "❌ Still broken: only auto_null sink found."
fi
