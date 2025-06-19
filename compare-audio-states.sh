#!/usr/bin/env bash

# ~/utono/system-config/compare-audio-states.sh
#
# 🔍 Compare two audio state logs side-by-side.
#
# Usage:
#   ~/utono/system-config/compare-audio-states.sh <old-log> <new-log>
#
# Example:
#   ~/utono/system-config/compare-audio-states.sh \
#     ~/audio-logs/2025-06-18-audio.txt \
#     ~/audio-logs/2025-07-01-audio.txt
#
# This script uses `diff` to highlight any changes between logs
# such as kernel updates, firmware differences, or sink changes.

file1="$1"
file2="$2"

if [[ -z "$file1" || -z "$file2" ]]; then
  echo "❌ Usage: $0 <old-audio-log> <new-audio-log>"
  exit 1
fi

if [[ ! -f "$file1" || ! -f "$file2" ]]; then
  echo "❌ One or both files do not exist."
  exit 1
fi

echo "🔍 Comparing:"
echo "  Old: $file1"
echo "  New: $file2"
echo

diff --color=always -u "$file1" "$file2" | less -R
