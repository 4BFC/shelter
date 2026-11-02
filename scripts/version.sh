#!/bin/bash
# Project-wide version functions. No installer or message-rendering dependencies.
# Return 1 for unreadable or invalid metadata; callers decide how to report it.

shelter_validate_version() {
  local value=${1:-} prerelease identifier
  local identifiers=()
  local pattern='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?(\+[0-9A-Za-z-]+(\.[0-9A-Za-z-]+)*)?$'
  [[ "$value" =~ $pattern ]] || return 1
  value=${value%%+*}
  if [[ "$value" == *-* ]]; then
    prerelease=${value#*-}
    IFS=. read -r -a identifiers <<< "$prerelease"
    for identifier in "${identifiers[@]}"; do
      if [[ "$identifier" =~ ^[0-9]+$ && "$identifier" == 0?* ]]; then
        return 1
      fi
    done
  fi
  return 0
}

shelter_read_version() {
  local value
  value=$(cat "$1" 2>/dev/null) || return 1
  shelter_validate_version "$value" || return 1
  printf '%s\n' "$value"
}
