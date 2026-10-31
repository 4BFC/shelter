#!/bin/bash
# Function definitions only: sourcing this file never installs tools.
# install.sh loads messages.sh before this file.

shelter_create_log() (
  local directory="${SHELTER_ENV_FILE%/*}/logs"
  umask 077
  mkdir -p "$directory" || return 1
  mktemp "$directory/install.XXXXXX"
)

shelter_check_platform() {
  local os major translated
  os=$(uname -s) || return 1
  [[ "$os" == Darwin ]] || { shelter_error macos_only; return 2; }
  SHELTER_ARCH=$(uname -m) || return 1
  SHELTER_OS_VERSION=$(sw_vers -productVersion) || return 1
  major=${SHELTER_OS_VERSION%%.*}
  case "$major" in ''|*[!0-9]*) shelter_error os_version_unknown; return 2 ;; esac
  [[ "$major" -ge 15 && "$SHELTER_ARCH" == arm64 ]] || {
    shelter_error unsupported_platform; return 2;
  }
  translated=$(sysctl -in sysctl.proc_translated 2>/dev/null) || translated=0
  [[ "$translated" != 1 ]] || { shelter_error rosetta_unsupported; return 2; }
  [[ "$(id -u)" != 0 ]] || { shelter_error root_unsupported; return 2; }
}

shelter_shell_targets() {
  [[ -n "${HOME:-}" && "$HOME" == /* ]] || { shelter_error home_unknown; return 2; }
  SHELTER_ENV_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/shelter/env.sh"
  case "${SHELL##*/}" in
    zsh) SHELTER_RC_FILES=("${ZDOTDIR:-$HOME}/.zshrc") ;;
    bash) SHELTER_RC_FILES=("$HOME/.bashrc" "$HOME/.bash_profile") ;;
    *) shelter_error shell_unsupported; return 2 ;;
  esac
}

shelter_add_path() {
  local dir=$1
  [[ -d "$dir" && "$dir" == /* ]] || return 0
  # Append to preserve the user's nvm/mise/pyenv precedence.
  case ":$PATH:" in *":$dir:"*) return 0 ;; esac
  PATH="$PATH:$dir"
  export PATH
  SHELTER_PATHS+=("$dir")
  hash -r
}

shelter_find_brew() {
  command -v brew 2>/dev/null && return 0
  [[ -x /opt/homebrew/bin/brew ]] && { printf '/opt/homebrew/bin/brew\n'; return 0; }
  return 1
}

shelter_find_vscode() {
  local path
  for path in '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code' \
    "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
    [[ -x "$path" ]] && { printf '%s\n' "$path"; return 0; }
  done
  return 1
}

shelter_find_ghostty() {
  local app
  for app in /Applications/Ghostty.app "$HOME/Applications/Ghostty.app"; do
    # Keep damaged app bundles visible so installation stops instead of replacing them.
    if [[ -e "$app" || -L "$app" ]]; then
      printf '%s/Contents/MacOS/ghostty\n' "$app"
      return 0
    fi
  done
  return 1
}

shelter_editor_paths() {
  local path
  path=$(shelter_find_vscode) || return 0
  shelter_add_path "${path%/*}"
}

shelter_refresh_paths() {
  local path
  SHELTER_BREW=$(shelter_find_brew) || SHELTER_BREW=''
  if [[ -n "$SHELTER_BREW" ]]; then
    SHELTER_PREFIX=$("$SHELTER_BREW" --prefix 2>/dev/null) || { shelter_error brew_run_failed; return 1; }
    [[ "$SHELTER_PREFIX" == /* && "$SHELTER_PREFIX" != *$'\n'* ]] || { shelter_error brew_path_invalid; return 1; }
    shelter_add_path "$SHELTER_PREFIX/bin"
    shelter_add_path "$SHELTER_PREFIX/sbin"
    shelter_add_path "$SHELTER_PREFIX/opt/node@24/bin"
  fi
  if command -v uv >/dev/null 2>&1; then
    path=$(uv --no-config python dir --bin 2>/dev/null) && shelter_add_path "$path"
  fi
  shelter_editor_paths
  return 0
}

shelter_probe_command() {
  local command=$1 output
  SHELTER_COMMAND_STATE=missing
  SHELTER_COMMAND_DETAIL=$(shelter_copy command_missing "$command")
  SHELTER_COMMAND_VERSION=$(shelter_copy not_installed)
  SHELTER_COMMAND_PATH=$(command -v "$command" 2>/dev/null) || return 0
  # Apple's git/python3 stubs can open an installation dialog even for --version.
  case "$SHELTER_COMMAND_PATH" in
    /usr/bin/git|/usr/bin/python3)
      if ! xcode-select -p >/dev/null 2>&1; then
        [[ -n "$SHELTER_PREFIX" && -x "$SHELTER_PREFIX/bin/$command" ]] || return 0
        SHELTER_COMMAND_PATH="$SHELTER_PREFIX/bin/$command"
      fi ;;
  esac
  if output=$("$SHELTER_COMMAND_PATH" --version 2>/dev/null) && [[ -n "$output" ]]; then
    SHELTER_COMMAND_STATE=ready
    SHELTER_COMMAND_VERSION=${output%%$'\n'*}
    SHELTER_COMMAND_DETAIL="$SHELTER_COMMAND_VERSION ($SHELTER_COMMAND_PATH)"
  else
    SHELTER_COMMAND_STATE=blocked
    SHELTER_COMMAND_VERSION=$(shelter_copy execution_check_failed)
    SHELTER_COMMAND_DETAIL=$(shelter_copy command_failed "$command" "$SHELTER_COMMAND_PATH")
  fi
}

shelter_probe_python() {
  local found installed
  shelter_probe_command python3
  if [[ "$SHELTER_COMMAND_PATH" == /usr/bin/python3 ]]; then
    SHELTER_COMMAND_STATE=missing
    SHELTER_COMMAND_VERSION=$(shelter_copy user_python_missing)
    SHELTER_COMMAND_DETAIL=$(shelter_copy user_python_missing_detail)
  fi
  [[ "$SHELTER_COMMAND_STATE" == missing ]] || return 0
  if command -v uv >/dev/null 2>&1; then
    # A read-only probe must not depend on writable access to uv's regular cache.
    if found=$(uv --no-cache --no-config --offline python find --managed-python --no-python-downloads 2>/dev/null); then
      if [[ "$found" == /* && -x "$found" ]]; then
        shelter_probe_command "$found"
        return 0
      fi
    else
      # find uses a non-zero exit code both for absence and for lookup errors.
      # Only an empty, successful installed list establishes that Python is absent.
      if installed=$(uv --no-cache --no-config --offline python list --only-installed --managed-python --no-python-downloads 2>/dev/null) && [[ -z "$installed" ]]; then
        return 0
      fi
    fi
    SHELTER_COMMAND_STATE=blocked
    SHELTER_COMMAND_VERSION=$(shelter_copy python_lookup_failed)
    SHELTER_COMMAND_DETAIL=$(shelter_copy python_lookup_failed_detail)
  fi
}

shelter_probe() {
  local tool=$1 first detail second path version
  case "$tool" in
    brew)
      if [[ -z "$SHELTER_BREW" ]]; then
        SHELTER_STATE=missing; SHELTER_DETAIL=$(shelter_copy brew_missing); SHELTER_VERSION=$(shelter_copy not_installed); return 0
      fi
      shelter_probe_command "$SHELTER_BREW" ;;
    git|gh) shelter_probe_command "$tool" ;;
    vscode)
      if path=$(shelter_find_vscode); then shelter_probe_command "$path"
      else SHELTER_STATE=missing; SHELTER_DETAIL=$(shelter_copy vscode_missing); SHELTER_VERSION=$(shelter_copy not_installed); return 0
      fi ;;
    ghostty)
      if path=$(shelter_find_ghostty); then
        if [[ ! -x "$path" ]]; then
          SHELTER_STATE=blocked; SHELTER_DETAIL=$(shelter_copy ghostty_invalid "$path"); SHELTER_VERSION=$(shelter_copy execution_check_failed); return 0
        fi
        shelter_probe_command "$path"
      else SHELTER_STATE=missing; SHELTER_DETAIL=$(shelter_copy ghostty_missing); SHELTER_VERSION=$(shelter_copy not_installed); return 0
      fi ;;
    node|python)
      if [[ "$tool" == node ]]; then shelter_probe_command node; else shelter_probe_python; fi
      first=$SHELTER_COMMAND_STATE; detail=$SHELTER_COMMAND_DETAIL; version=$SHELTER_COMMAND_VERSION
      if [[ "$tool" == node ]]; then shelter_probe_command npm; else shelter_probe_command uv; fi
      second=$SHELTER_COMMAND_STATE
      SHELTER_DETAIL="$detail; $SHELTER_COMMAND_DETAIL"
      SHELTER_VERSION="$version / $SHELTER_COMMAND_VERSION"
      if [[ "$first" == blocked || "$second" == blocked ]]; then SHELTER_STATE=blocked
      elif [[ "$first" == ready && "$second" == ready ]]; then SHELTER_STATE=ready
      elif [[ "$first" == missing && "$second" == missing ]]; then SHELTER_STATE=missing
      elif [[ "$tool" == node ]]; then SHELTER_STATE=blocked
      else SHELTER_STATE=partial
      fi
      return 0 ;;
  esac
  SHELTER_STATE=$SHELTER_COMMAND_STATE
  SHELTER_DETAIL=$SHELTER_COMMAND_DETAIL
  SHELTER_VERSION=$SHELTER_COMMAND_VERSION
}

shelter_bootstrap_brew() (
  local download
  umask 077
  download=$(mktemp "${TMPDIR:-/tmp}/shelter-homebrew.XXXXXX") || return 1
  trap 'rm -f "$download"' EXIT
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    --connect-timeout 15 --max-time 120 \
    https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$download" || return 1
  /bin/bash "$download"
)

shelter_ensure_brew() {
  if [[ -z "$SHELTER_BREW" ]]; then
    if [[ -n "${SHELTER_LOG_FILE:-}" ]]; then
      # The official bootstrapper reads confirmations and may request sudo.
      # Keep those prompts visible through the console descriptors saved by main.
      shelter_bootstrap_brew >&3 2>&4 || return 1
    else
      shelter_bootstrap_brew || return 1
    fi
    shelter_refresh_paths || return 1
  fi
  shelter_probe brew
  [[ "$SHELTER_STATE" == ready ]] || { shelter_error brew_verification_failed; return 1; }
}

shelter_brew_install() {
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_INSTALL_UPGRADE=1 \
    "$SHELTER_BREW" install "$@"
}

shelter_install_tool() {
  case "$1" in
    brew) return 0 ;;
    git|gh) shelter_brew_install "$1" ;;
    vscode) shelter_brew_install --cask --no-binaries visual-studio-code ;;
    ghostty) shelter_brew_install --cask ghostty ;;
    node) shelter_brew_install node@24 ;;
    python)
      shelter_probe_command uv
      if [[ "$SHELTER_COMMAND_STATE" != ready ]]; then
        shelter_brew_install uv || return 1
        shelter_refresh_paths || return 1
      fi
      shelter_probe_python
      if [[ "$SHELTER_COMMAND_STATE" != ready ]]; then
        uv --no-config python install 3.14 || return 1
      fi
      return 0 ;;
  esac
}

shelter_save_paths() (
  local directory candidate rc line backup dir quoted
  [[ ${#SHELTER_PATHS[@]} -gt 0 ]] || return 0
  umask 077
  directory=${SHELTER_ENV_FILE%/*}
  mkdir -p "$directory" || return 1
  if [[ -e "$SHELTER_ENV_FILE" || -L "$SHELTER_ENV_FILE" ]]; then
    [[ -f "$SHELTER_ENV_FILE" && ! -L "$SHELTER_ENV_FILE" ]] || { shelter_error env_not_regular; return 1; }
    IFS= read -r line < "$SHELTER_ENV_FILE"
    [[ "$line" == '# Generated by Shelter Lite' ]] || { shelter_error env_overwrite_refused "$SHELTER_ENV_FILE"; return 1; }
  fi
  candidate=$(mktemp "$directory/.env.XXXXXX") || return 1
  trap 'rm -f "$candidate"' EXIT
  if [[ -f "$SHELTER_ENV_FILE" ]]; then cp "$SHELTER_ENV_FILE" "$candidate" || return 1
  else printf '# Generated by Shelter Lite\n' > "$candidate" || return 1
  fi
  for dir in "${SHELTER_PATHS[@]}"; do
    printf -v quoted '%q' "$dir"
    line="case \":\${PATH}:\" in *\":\"$quoted\":\"*) ;; *) export PATH=\"\${PATH}:\"$quoted ;; esac"
    grep -Fqx -- "$line" "$candidate" || printf '%s\n' "$line" >> "$candidate" || return 1
  done
  /bin/bash -n "$candidate" || return 1
  if [[ -f "$SHELTER_ENV_FILE" ]] && ! cmp -s "$candidate" "$SHELTER_ENV_FILE"; then
    backup=$(mktemp "$directory/env.sh.backup.XXXXXX") || return 1
    cp -p "$SHELTER_ENV_FILE" "$backup" || return 1
    shelter_print env_backup "$backup"
  fi
  mv "$candidate" "$SHELTER_ENV_FILE" || return 1
  printf -v quoted '%q' "$SHELTER_ENV_FILE"
  line="[ ! -f $quoted ] || . $quoted # Shelter Lite"
  for rc in "${SHELTER_RC_FILES[@]}"; do
    [[ ! -L "$rc" || -f "$rc" ]] || { shelter_error symlink_target_missing "$rc"; return 1; }
    [[ ! -e "$rc" || -f "$rc" ]] || { shelter_error rc_not_regular "$rc"; return 1; }
    if [[ -f "$rc" ]]; then
      grep -Fqx -- "$line" "$rc" && continue
      backup=$(mktemp "$directory/shell.backup.XXXXXX") || return 1
      cp -p "$rc" "$backup" || return 1
      shelter_print rc_backup "$rc" "$backup"
    fi
    mkdir -p "${rc%/*}" || return 1
    printf '\n%s\n' "$line" >> "$rc" || return 1
  done
)
