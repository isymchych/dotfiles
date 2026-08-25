resolved_hostname=
known_host=0
features=()
pacman_packages=()
aur_packages=()
enabled_system_services=()
disabled_system_services=()
enabled_user_services=()
disabled_user_services=()
greetd_autologin=0
tlp_configured=0
tlp_battery=
tlp_start=
tlp_stop=

# shellcheck disable=SC2034 # Each consumer uses only part of the shared resolved state.
while IFS=$'\t' read -r record first second third extra; do
  if [[ -n "$extra" ]]; then
    printf 'Invalid resolved host state record: %s\n' "$record" >&2
    exit 1
  fi

  case "$record" in
    host)
      resolved_hostname=$first
      ;;
    known_host)
      if [[ "$first" == true ]]; then
        known_host=1
      fi
      ;;
    feature)
      features+=("$first")
      ;;
    package)
      case "$first" in
        pacman) pacman_packages+=("$second") ;;
        aur) aur_packages+=("$second") ;;
        *)
          printf 'Unknown package provider in resolved host state: %s\n' "$first" >&2
          exit 1
          ;;
      esac
      ;;
    service)
      case "$first:$second" in
        system:enabled) enabled_system_services+=("$third") ;;
        system:disabled) disabled_system_services+=("$third") ;;
        user:enabled) enabled_user_services+=("$third") ;;
        user:disabled) disabled_user_services+=("$third") ;;
        *)
          printf 'Unknown service state in resolved host state: %s:%s\n' \
            "$first" "$second" >&2
          exit 1
          ;;
      esac
      ;;
    greetd_autologin)
      if [[ "$first" == true ]]; then
        greetd_autologin=1
      fi
      ;;
    tlp)
      tlp_configured=1
      tlp_battery=$first
      tlp_start=$second
      tlp_stop=$third
      ;;
    "")
      ;;
    *)
      printf 'Unknown resolved host state record: %s\n' "$record" >&2
      exit 1
      ;;
  esac
done <<'ACCEL_OS_RESOLVED_HOST_STATE'
{{ template "resolved-host-state" . -}}
ACCEL_OS_RESOLVED_HOST_STATE

has_feature() {
  local expected=$1
  local feature

  for feature in "${features[@]}"; do
    if [[ "$feature" == "$expected" ]]; then
      return 0
    fi
  done

  return 1
}