#!/usr/bin/env bash
set -euo pipefail

readonly BULLET='•'

failed_units() {
  local scope=$1
  local -a command=(systemctl)

  if [[ "$scope" == user ]]; then
    command+=(--user)
  fi

  "${command[@]}" --failed --no-legend --plain --no-pager 2>/dev/null |
    awk '{print $1}'
}

unit_description() {
  local scope=$1
  local unit=$2
  local -a command=(systemctl)

  if [[ "$scope" == user ]]; then
    command+=(--user)
  fi

  "${command[@]}" show "$unit" --property=Description --value 2>/dev/null ||
    printf 'Description unavailable\n'
}

append_scope_tooltip() {
  local scope=$1
  local label=$2
  shift 2
  local -a units=("$@")
  local unit description

  ((${#units[@]} > 0)) || return 0

  tooltip+=$'\n\n'"$label:"
  for unit in "${units[@]}"; do
    description=$(unit_description "$scope" "$unit")
    tooltip+=$'\n'"$BULLET $unit — $description"
  done
}

emit_status() {
  local -a system_units=()
  local -a user_units=()
  local tooltip text

  mapfile -t system_units < <(failed_units system)
  mapfile -t user_units < <(failed_units user)

  local total=$((${#system_units[@]} + ${#user_units[@]}))
  if ((total == 0)); then
    jq -cn '{
      text: "",
      tooltip: "No failed systemd units",
      class: ["systemd-failed-units", "systemd-failed-units--ok"]
    }'
    return
  fi

  text="✗ $total"
  if ((total == 1)); then
    tooltip='1 failed systemd unit'
  else
    tooltip="$total failed systemd units"
  fi

  append_scope_tooltip system 'System' "${system_units[@]}"
  append_scope_tooltip user 'User' "${user_units[@]}"
  tooltip+=$'\n\nLeft-click: open statuses and recent logs'
  tooltip+=$'\n\nManual workflow:'
  tooltip+=$'\n1. systemctl --failed'
  tooltip+=$'\n2. systemctl status <unit>'
  tooltip+=$'\n3. journalctl -b -u <unit>'

  jq -cn \
    --arg text "$text" \
    --arg tooltip "$tooltip" \
    '{
      text: $text,
      tooltip: $tooltip,
      class: ["systemd-failed-units", "systemd-failed-units--degraded"]
    }'
}

print_scope_report() {
  local scope=$1
  local label=$2
  shift 2
  local -a units=("$@")
  local unit
  local -a systemctl_command=(systemctl)
  local -a journalctl_command=(journalctl)

  if [[ "$scope" == user ]]; then
    systemctl_command+=(--user)
    journalctl_command+=(--user)
  fi

  printf '\n== %s failed units ==\n' "$label"
  if ((${#units[@]} == 0)); then
    printf 'None\n'
    return
  fi

  for unit in "${units[@]}"; do
    printf '\n-- %s --\n' "$unit"
    "${systemctl_command[@]}" status "$unit" --no-pager --full || true
    printf '\nRecent boot log:\n'
    "${journalctl_command[@]}" -b -u "$unit" --no-pager -n 30 || true
  done
}

inspect_failures() {
  local -a system_units=()
  local -a user_units=()

  mapfile -t system_units < <(failed_units system)
  mapfile -t user_units < <(failed_units user)

  printf 'systemd failure diagnostics\n'
  printf 'Generated: %s\n' "$(date --iso-8601=seconds)"
  print_scope_report system 'System' "${system_units[@]}"
  print_scope_report user 'User' "${user_units[@]}"

  printf '\n== Workflow ==\n'
  printf '1. Read the unit status and its first error.\n'
  printf '2. Follow the boot log backward to the triggering event.\n'
  printf '3. Inspect the unit with: systemctl cat <unit>\n'
  printf '4. Fix the cause, then restart the unit.\n'
  printf '5. Clear stale failure state only after fixing it:\n'
  printf '   systemctl reset-failed <unit>\n'
  printf '\nPress Enter to close.'
  read -r _
}

case "${1:-status}" in
  status)
    emit_status
    ;;
  inspect)
    inspect_failures
    ;;
  *)
    printf 'usage: %s [status|inspect]\n' "$0" >&2
    exit 2
    ;;
esac
