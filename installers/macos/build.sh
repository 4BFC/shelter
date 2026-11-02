#!/bin/bash
# Bundle the canonical shell sources using tools included with macOS Bash 3.2.

SHELTER_BUILD_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
source "$SHELTER_BUILD_DIR/messages.sh" || exit 1

shelter_write_bundle() {
  printf '#!/bin/bash\n# Shelter Lite standalone installer — generated; do not edit.\n# Source: https://github.com/4BFC/shelter\n\n' || return 1
  sed 's/^/# /' "$SHELTER_BUILD_DIR/../../LICENSE" || return 1
  printf '\n' || return 1
  cat "$SHELTER_BUILD_DIR/messages.sh" "$SHELTER_BUILD_DIR/tools.sh" || return 1
  # Remove only the explicitly marked imports; retain the entry point and main guard.
  # Fail if the markers drift so an incomplete bundle cannot be published by accident.
  awk '
    /^# BEGIN SHELTER SOURCE IMPORTS$/ { if (begins++) exit 1; skip=1; next }
    /^# END SHELTER SOURCE IMPORTS$/ { if (!skip || ends++) exit 1; skip=0; next }
    !skip { print }
    END { if (begins != 1 || ends != 1 || skip) exit 1 }
  ' "$SHELTER_BUILD_DIR/install.sh"
}

shelter_build() (
  local output_dir=$1 stage artifact=shelter-lite-macos.sh
  local archive=shelter-lite-macos.zip clickable='Shelter Lite.command' target
  mkdir -p "$output_dir" || return 1
  output_dir=$(CDPATH= cd -- "$output_dir" && pwd -P) || return 1
  stage=$(mktemp -d "$output_dir/.shelter-build.XXXXXX") || return 1
  trap 'rm -rf "$stage"' EXIT
  shelter_write_bundle > "$stage/$artifact" || return 1
  /bin/bash -n "$stage/$artifact" || return 1
  chmod 755 "$stage/$artifact" || return 1
  cp "$stage/$artifact" "$stage/$clickable" || return 1
  chmod 755 "$stage/$clickable" || return 1
  # ZIP carries executable permissions. Fix its entry timestamp and omit host metadata
  # so rebuilding the same sources produces the same archive on this toolchain.
  TZ=UTC touch -t 198001010000 "$stage/$clickable" || return 1
  (cd -- "$stage" && TZ=UTC zip -X -q "$archive" "$clickable") || return 1
  for target in "$artifact" "$archive"; do
    (cd -- "$stage" && shasum -a 256 "$target" > "$target.sha256") || return 1
  done
  # Rebuild only these named outputs, preserving any other files in the directory.
  for target in "$artifact" "$artifact.sha256" "$archive" "$archive.sha256"; do
    [[ ! -d "$output_dir/$target" ]] || return 1
  done
  for target in "$artifact" "$archive"; do
    mv -f "$stage/$target" "$output_dir/$target" || return 1
    mv -f "$stage/$target.sha256" "$output_dir/$target.sha256" || return 1
    shelter_print build_complete "$output_dir/$target"
    shelter_print build_checksum "$output_dir/$target.sha256"
  done
)

shelter_build_main() {
  local output_dir="$SHELTER_BUILD_DIR/../../dist"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --output-dir)
        [[ $# -ge 2 && -n "$2" && "$2" != -* ]] || { shelter_error option_value_required "$1"; return 2; }
        output_dir=$2
        shift ;;
      -h|--help) shelter_build_help; return 0 ;;
      *) shelter_error unknown_option "$1"; return 2 ;;
    esac
    shift
  done
  shelter_build "$output_dir" || { shelter_error build_failed; return 1; }
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  shelter_build_main "$@"
  exit $?
fi
