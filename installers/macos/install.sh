#!/bin/bash
# macOS ships Bash 3.2. Keep this entry point compatible with it.

SHELTER_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
# shellcheck source=tools.sh
source "$SHELTER_SCRIPT_DIR/tools.sh" || exit 1

shelter_help() {
  cat <<'HELP'
Shelter Lite — A shelter for your environment

Usage: /bin/bash installers/macos/install.sh [options]

  --check         Check installed tools only. Exit 1 if any tool is missing or fails
  --dry-run       Show the installation plan. No downloads or configuration changes
  --mode lite     Lite version (default). full is not available yet
  --color MODE    Colors: auto (default), always (force), never (off)
  -h, --help      Show help

Without options, prepare the entire fixed tool set in order. There is no tool selection menu.
Homebrew → Git → VS Code → Node.js/npm → Python/uv → GitHub CLI
Supported: macOS 15 or later, Apple Silicon, zsh/bash. Do not run with sudo.
Skip existing tools that run successfully. Homebrew handles dependencies for new packages.
New installations use Node.js 24 and Python 3.14 managed by uv.
The default output shows the final result and brief guidance, with warnings when needed.
Details are saved in logs/ under the configuration directory.
HELP
}

shelter_tool_name() {
  case "$1" in
    brew) printf 'Homebrew' ;;
    git) printf 'Git' ;;
    vscode) printf 'VS Code' ;;
    node) printf 'Node.js + npm' ;;
    python) printf 'Python + uv' ;;
    gh) printf 'GitHub CLI' ;;
  esac
}

shelter_results() {
  local i tone row
  shelter_section 'Installation results'
  printf '  Tool | Result | Before installation → Verified result\n\n'
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    case "${SHELTER_RESULTS[$i]}" in
      Failed) tone=error ;;
      'Not run') tone=warning ;;
      *) tone=success ;;
    esac
    printf -v row '  %-16s | %s | %s → %s' "$(shelter_tool_name "${SHELTER_TOOLS[$i]}")" \
      "${SHELTER_RESULTS[$i]}" "${SHELTER_BEFORE[$i]}" "${SHELTER_AFTER[$i]}"
    shelter_text "$tone" '●'
    printf '%s\n' "$row"
  done
}

shelter_plan() {
  local tool missing=0 blocked=0 status action tone row
  if [[ "$SHELTER_ACTION" == check ]]; then
    shelter_section 'Current status'
    printf '  Tool | Status | Observed version and executable path\n\n'
  else
    shelter_section 'Before installation'
    printf '  Tool | Current status | Planned action\n\n'
  fi
  for tool in "${SHELTER_TOOLS[@]}"; do
    shelter_probe "$tool"
    SHELTER_BEFORE+=("$SHELTER_VERSION")
    SHELTER_RESULTS+=('Not run')
    SHELTER_AFTER+=('Not checked after execution')
    case "$SHELTER_STATE" in
      ready) status='Installed'; action='Keep the existing installation'; tone=success ;;
      blocked) status='Check required'; action='Repair the existing environment'; tone=error; blocked=1 ;;
      partial) status='Partially installed'; action='Install missing components'; tone=warning; missing=1 ;;
      *) status='Not installed'; action='Install new'; tone=warning; missing=1 ;;
    esac
    if [[ "$SHELTER_ACTION" == check ]]; then
      printf -v row '  %-16s | %s | %s' "$(shelter_tool_name "$tool")" "$status" "$SHELTER_DETAIL"
    else
      printf -v row '  %-16s | %s (%s) | %s' "$(shelter_tool_name "$tool")" "$status" "$SHELTER_VERSION" "$action"
    fi
    shelter_text "$tone" '●'
    printf '%s\n' "$row"
  done
  if [[ "$SHELTER_ACTION" == check ]]; then
    if [[ $missing == 0 && $blocked == 0 ]]; then
      shelter_section 'Check complete' success
      printf 'All tools can run. No installation or configuration changes were made.\n'
      return 0
    fi
    shelter_section 'Check required' warning
    printf 'Some tools are missing or failed to run. No installation or configuration changes were made.\n'
    return 1
  fi
  if [[ $missing == 1 ]]; then
    shelter_probe brew
    if [[ "$SHELTER_STATE" == blocked ]]; then
      blocked=1
      shelter_error "Homebrew needs attention: $SHELTER_DETAIL"
    elif [[ "$SHELTER_STATE" != ready ]]; then
      shelter_message warning 'An actual installation runs the official Homebrew installer. Administrator authentication and developer tools may be required.'
    fi
    shelter_section 'Planned installations'
    printf 'Only missing components will be installed.\n'
    for tool in "${SHELTER_TOOLS[@]}"; do
      shelter_probe "$tool"
      [[ "$SHELTER_STATE" == ready || "$SHELTER_STATE" == blocked ]] || shelter_describe_install "$tool"
    done
  else
    printf '\nNo new tools need to be installed.\n'
  fi
  if [[ ${#SHELTER_PATHS[@]} -gt 0 || $missing == 1 ]]; then
    shelter_section 'Planned configuration'
    printf 'Save the required executable paths and load them from the shell configuration. Back up existing files before changing them.\n'
    printf '  Environment file: %s\n' "$SHELTER_ENV_FILE"
    printf '  Shell configuration: %s\n' "${SHELTER_RC_FILES[@]}"
  fi
  [[ $blocked == 0 ]] || { shelter_error 'Some tools fail to run, or Node.js/npm is only partially installed. Repair the existing installation first.'; return 1; }
}

shelter_main() {
  set -o pipefail
  local mode=lite option status
  SHELTER_ACTION=install
  SHELTER_TOOLS=(brew git vscode node python gh)
  SHELTER_PATHS=()
  SHELTER_RC_FILES=()
  SHELTER_BEFORE=()
  SHELTER_RESULTS=()
  SHELTER_AFTER=()
  SHELTER_BREW=''
  SHELTER_PREFIX=''
  SHELTER_LOG_FILE=''
  SHELTER_FAILURE_MESSAGE=''
  SHELTER_INSTALL_ATTEMPTED=0
  SHELTER_SETTINGS_ATTEMPTED=0
  SHELTER_COLOR=auto
  while [[ $# -gt 0 ]]; do
    option=$1
    case "$option" in
      -h|--help) shelter_help; return 0 ;;
      --mode)
        [[ $# -ge 2 && "$2" != --* ]] || { shelter_error "A value is required for $option."; return 2; }
        mode=$2
        shift ;;
      --color)
        [[ $# -ge 2 ]] || { shelter_error 'A value is required for --color.'; return 2; }
        case "$2" in auto|always|never) SHELTER_COLOR=$2 ;; *) shelter_error '--color must be auto, always, or never.'; return 2 ;; esac
        shift ;;
      --check|--dry-run)
        [[ "$SHELTER_ACTION" == install ]] || { shelter_error '--check and --dry-run cannot be combined.'; return 2; }
        SHELTER_ACTION=${option#--} ;;
      *) shelter_error "Unknown option: $option"; return 2 ;;
    esac
    shift
  done
  case "$mode" in
    lite) ;;
    full) shelter_error 'The full version is not available yet. Use Lite instead.'; return 2 ;;
    *) shelter_error 'The supported mode is lite.'; return 2 ;;
  esac
  shelter_check_platform || return
  shelter_shell_targets || return
  if [[ "$SHELTER_ACTION" != install ]]; then
    shelter_run
    return $?
  fi
  if ! SHELTER_LOG_FILE=$(shelter_create_log); then
    shelter_notice failure 'Could not create the installation log.'
    shelter_message info 'Check access permissions for the configuration directory, then try again.'
    return 1
  fi
  shelter_notice notification
  status=0
  shelter_run 3>&1 4>&2 > "$SHELTER_LOG_FILE" 2>&1 || status=$?
  if [[ $status == 0 ]]; then
    shelter_notice success
    if [[ ${#SHELTER_PATHS[@]} -gt 0 ]]; then
      shelter_notice warning
    fi
  else
    shelter_notice failure "${SHELTER_FAILURE_MESSAGE:-Could not complete the installation.}"
    if [[ $SHELTER_INSTALL_ATTEMPTED == 1 || $SHELTER_SETTINGS_ATTEMPTED == 1 ]]; then
      shelter_message warning 'Installation and configuration changes already made are not rolled back automatically.'
    fi
    shelter_message info 'Check the detailed log, resolve the issue, then run the installer again.'
    shelter_message info "Detailed log: $SHELTER_LOG_FILE"
  fi
  return "$status"
}

shelter_run() {
  local tool i status result name
  local SHELTER_COLOR=${SHELTER_COLOR:-auto}
  # Installation details go to a plain log, regardless of console color mode.
  [[ "$SHELTER_ACTION" != install ]] || SHELTER_COLOR=never
  shelter_refresh_paths || return
  printf 'Shelter Lite — macOS %s / %s\n' "$SHELTER_OS_VERSION" "$SHELTER_ARCH"
  case "$SHELTER_ACTION" in
    dry-run)
      shelter_section 'Dry run'
      printf 'No actual installation or configuration changes will be made.\n' ;;
    check)
      shelter_section 'Status check'
      printf 'Checking the current installation status only.\n' ;;
    install)
      shelter_section 'Installation mode'
      printf 'Starting setup for the entire fixed tool set.\n' ;;
  esac
  shelter_plan || return
  if [[ "$SHELTER_ACTION" == dry-run ]]; then
    shelter_section 'Dry run complete' success
    printf 'Actual installations: 0, configuration changes: 0.\n'
    return 0
  fi
  [[ "$SHELTER_ACTION" == install ]] || return 0
  shelter_section 'Installation progress'
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    tool=${SHELTER_TOOLS[$i]}
    name=$(shelter_tool_name "$tool")
    shelter_probe "$tool"
    if [[ "$SHELTER_STATE" == ready ]]; then
      SHELTER_RESULTS[$i]='Existing installation kept'
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_message success "Existing installation kept: $name — $SHELTER_VERSION"
      continue
    fi
    if [[ "$SHELTER_STATE" == blocked ]]; then
      SHELTER_RESULTS[$i]='Failed'
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_results
      shelter_error "The status of $name changed: $SHELTER_DETAIL"
      return 1
    fi
    result='New installation complete'
    [[ "$SHELTER_STATE" != partial ]] || result='Missing components installed'
    shelter_message info "Installing $name"
    printf '%s\n' "--- Installer log start: $name ---"
    status=0
    SHELTER_INSTALL_ATTEMPTED=1
    shelter_ensure_brew && shelter_install_tool "$tool" && shelter_refresh_paths || status=1
    printf '%s\n' "--- Installer log end: $name ---"
    shelter_probe "$tool"
    SHELTER_AFTER[$i]=$SHELTER_VERSION
    if [[ $status != 0 || "$SHELTER_STATE" != ready ]]; then
      SHELTER_RESULTS[$i]='Failed'
      shelter_results
      printf 'Verification details: %s\n' "$SHELTER_DETAIL"
      shelter_error "Installation or verification failed for $name"
      printf 'Completed installations and partially installed components remain. Resolve the error and retry the same command.\n' >&2
      return 1
    fi
    SHELTER_RESULTS[$i]=$result
    shelter_message success "Installation complete for $name — $SHELTER_VERSION"
  done
  shelter_results
  shelter_section 'Shell configuration'
  [[ ${#SHELTER_PATHS[@]} == 0 ]] || SHELTER_SETTINGS_ATTEMPTED=1
  shelter_save_paths || { shelter_error 'The tools are installed, but shell configuration failed.'; return 1; }
  if [[ ${#SHELTER_PATHS[@]} -gt 0 ]]; then
    shelter_message warning 'Path settings were saved but are not active in the current terminal yet.'
    printf 'To activate the paths in the current terminal, run:\n  source %q\n' "$SHELTER_ENV_FILE"
    printf 'Also check in a new terminal. Restart running programs to use the new environment.\n'
  else
    shelter_message success 'No executable paths need to be added.'
  fi
  shelter_section 'Installation complete' success
  printf 'All Lite tools have been verified.\n'
  printf 'Use --check to inspect versions and executable paths. It does not check security vulnerabilities or whether versions are current.\n'
  printf 'Configure your Git identity and GitHub login separately.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'printf "\nInterrupted. Completed installations are preserved.\n" >&2; exit 130' INT
  shelter_main "$@"
  exit $?
fi
