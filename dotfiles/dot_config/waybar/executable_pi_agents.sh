#!/usr/bin/env bash
set -euo pipefail

runtime_root="${XDG_RUNTIME_DIR:-/tmp/accel-os-${UID:-unknown}}"
state_dir="$runtime_root/accel-os/pi-agents"
working_count=0

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
    [[ "$state" == "working" ]] || continue

    (( working_count += 1 ))
  done
fi

if (( working_count == 0 )); then
  printf '{"text":"","tooltip":"No Pi coding agents working","class":["pi-agents","pi-agents--idle"]}\n'
  exit 0
fi

if (( working_count == 1 )); then
  tooltip="1 Pi coding agent working"
else
  tooltip="$working_count Pi coding agents working"
fi

printf '{"text":"󰚩 %d","tooltip":"%s","class":["pi-agents","pi-agents--working"]}\n' "$working_count" "$tooltip"
