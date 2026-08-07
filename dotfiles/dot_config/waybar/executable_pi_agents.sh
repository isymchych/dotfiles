#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/tmp/accel-os-${UID:-unknown}}"
state_dir="$runtime_root/accel-os/pi-agents"
working_count=0
idle_count=0

if [[ -d "$state_dir" ]]; then
  shopt -s nullglob
  for state_file in "$state_dir"/*.state; do
    pid=${state_file##*/}
    pid=${pid%.state}

    [[ "$pid" =~ ^[0-9]+$ ]] || continue
    [[ -r "/proc/$pid/cmdline" ]] || continue

    cmdline=$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null) || continue
    [[ "$cmdline" == *"/ai/pi/ai.ts"* ]] || continue

    IFS= read -r state <"$state_file" || continue
    case "$state" in
      working)
        (( working_count += 1 ))
        ;;
      idle)
        (( idle_count += 1 ))
        ;;
    esac
  done
fi

total_count=$((working_count + idle_count))

if (( total_count == 0 )); then
  printf '{"text":"","tooltip":"No Pi coding agents running","class":["pi-agents","pi-agents--none"]}\n'
  exit 0
fi

if (( working_count == 1 && idle_count == 1 )); then
  tooltip="1 Pi coding agent working, 1 waiting"
elif (( working_count == 1 )); then
  tooltip="1 Pi coding agent working, $idle_count waiting"
elif (( idle_count == 1 )); then
  tooltip="$working_count Pi coding agents working, 1 waiting"
else
  tooltip="$working_count Pi coding agents working, $idle_count waiting"
fi

if (( working_count > 0 )); then
  class="pi-agents--working"
else
  class="pi-agents--waiting"
fi

printf '{"text":"󰚩 <span color='\''#ebcb8b'\''>%d</span>/<span color='\''#90b1b1'\''>%d</span>","tooltip":"%s","class":["pi-agents","%s"]}\n' \
  "$working_count" \
  "$idle_count" \
  "$tooltip" \
  "$class"
