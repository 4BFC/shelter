#!/bin/bash
# macOS ships Bash 3.2. Keep this entry point compatible with it.

SHELTER_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
# shellcheck source=messages.sh
source "$SHELTER_SCRIPT_DIR/messages.sh" || exit 1
# shellcheck source=tools.sh
source "$SHELTER_SCRIPT_DIR/tools.sh" || exit 1

shelter_plan() {
  local tool missing=0 blocked=0 rc
  shelter_plan_heading "$SHELTER_ACTION"
  for tool in "${SHELTER_TOOLS[@]}"; do
    shelter_probe "$tool"
    SHELTER_BEFORE+=("$SHELTER_VERSION")
    SHELTER_RESULTS+=(not_run)
    SHELTER_AFTER+=("$(shelter_copy not_checked)")
    case "$SHELTER_STATE" in
      ready) ;;
      blocked) blocked=1 ;;
      *) missing=1 ;;
    esac
    shelter_plan_row "$tool" "$SHELTER_STATE" "$SHELTER_ACTION" "$SHELTER_DETAIL" "$SHELTER_VERSION"
  done
  if [[ "$SHELTER_ACTION" == check ]]; then
    if [[ $missing == 0 && $blocked == 0 ]]; then
      shelter_section check_complete success
      shelter_print check_complete_summary
      return 0
    fi
    shelter_section check_required warning
    shelter_print check_required_summary
    return 1
  fi
  if [[ $missing == 1 ]]; then
    shelter_probe brew
    if [[ "$SHELTER_STATE" == blocked ]]; then
      blocked=1
      shelter_error brew_needs_attention "$SHELTER_DETAIL"
    elif [[ "$SHELTER_STATE" != ready ]]; then
      shelter_message warning brew_bootstrap_warning
    fi
    shelter_section planned_installations
    shelter_print missing_only
    for tool in "${SHELTER_TOOLS[@]}"; do
      shelter_probe "$tool"
      [[ "$SHELTER_STATE" == ready || "$SHELTER_STATE" == blocked ]] || shelter_describe_install "$tool"
    done
  else
    shelter_print nothing_to_install
  fi
  if [[ ${#SHELTER_PATHS[@]} -gt 0 || $missing == 1 ]]; then
    shelter_section planned_configuration
    shelter_print configuration_plan
    shelter_print env_path "$SHELTER_ENV_FILE"
    for rc in "${SHELTER_RC_FILES[@]}"; do shelter_print rc_path "$rc"; done
  fi
  [[ $blocked == 0 ]] || { shelter_error existing_install_blocked; return 1; }
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
  SHELTER_COLOR=$SHELTER_DEFAULT_COLOR
  while [[ $# -gt 0 ]]; do
    option=$1
    case "$option" in
      -h|--help) shelter_help; return 0 ;;
      --mode)
        [[ $# -ge 2 && "$2" != --* ]] || { shelter_error option_value_required "$option"; return 2; }
        mode=$2
        shift ;;
      --color)
        SHELTER_COLOR=always
        if [[ $# -gt 1 && "$2" != -* ]]; then
          case "$2" in auto|always|never) SHELTER_COLOR=$2 ;; *) shelter_error invalid_color; return 2 ;; esac
          shift
        fi ;;
      --check|--dry-run)
        [[ "$SHELTER_ACTION" == install ]] || { shelter_error conflicting_actions; return 2; }
        SHELTER_ACTION=${option#--} ;;
      *) shelter_error unknown_option "$option"; return 2 ;;
    esac
    shift
  done
  case "$mode" in
    lite) ;;
    full) shelter_error full_unavailable; return 2 ;;
    *) shelter_error invalid_mode; return 2 ;;
  esac
  shelter_check_platform || return
  shelter_shell_targets || return
  if [[ "$SHELTER_ACTION" != install ]]; then
    shelter_run
    return $?
  fi
  if ! SHELTER_LOG_FILE=$(shelter_create_log); then
    shelter_notice failure log_creation_failed
    shelter_message info check_config_permissions
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
    shelter_notice failure
    if [[ $SHELTER_INSTALL_ATTEMPTED == 1 || $SHELTER_SETTINGS_ATTEMPTED == 1 ]]; then
      shelter_message warning no_rollback
    fi
    shelter_message info retry_guidance
    shelter_message info log_path "$SHELTER_LOG_FILE"
  fi
  return "$status"
}

shelter_run() {
  local tool i status result name
  local SHELTER_COLOR=${SHELTER_COLOR:-$SHELTER_DEFAULT_COLOR}
  # Installation details go to a plain log, regardless of console color mode.
  [[ "$SHELTER_ACTION" != install ]] || SHELTER_COLOR=never
  shelter_refresh_paths || return
  shelter_print platform_banner "$SHELTER_OS_VERSION" "$SHELTER_ARCH"
  case "$SHELTER_ACTION" in
    dry-run)
      shelter_section dry_run
      shelter_print dry_run_intro ;;
    check)
      shelter_section status_check
      shelter_print check_intro ;;
    install)
      shelter_section installation_mode
      shelter_print install_intro ;;
  esac
  shelter_plan || return
  if [[ "$SHELTER_ACTION" == dry-run ]]; then
    shelter_section dry_run_complete success
    shelter_print dry_run_summary
    return 0
  fi
  [[ "$SHELTER_ACTION" == install ]] || return 0
  shelter_section installation_progress
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    tool=${SHELTER_TOOLS[$i]}
    name=$(shelter_tool_name "$tool")
    shelter_probe "$tool"
    if [[ "$SHELTER_STATE" == ready ]]; then
      SHELTER_RESULTS[$i]=kept
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_message success existing_kept "$name" "$SHELTER_VERSION"
      continue
    fi
    if [[ "$SHELTER_STATE" == blocked ]]; then
      SHELTER_RESULTS[$i]=failed
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_results
      shelter_error status_changed "$name" "$SHELTER_DETAIL"
      return 1
    fi
    result=installed
    [[ "$SHELTER_STATE" != partial ]] || result=completed
    shelter_message info installing "$name"
    shelter_print installer_log_start "$name"
    status=0
    SHELTER_INSTALL_ATTEMPTED=1
    shelter_ensure_brew && shelter_install_tool "$tool" && shelter_refresh_paths || status=1
    shelter_print installer_log_end "$name"
    shelter_probe "$tool"
    SHELTER_AFTER[$i]=$SHELTER_VERSION
    if [[ $status != 0 || "$SHELTER_STATE" != ready ]]; then
      SHELTER_RESULTS[$i]=failed
      shelter_results
      shelter_print verification_details "$SHELTER_DETAIL"
      shelter_error install_failed "$name"
      shelter_print partial_install_remains >&2
      return 1
    fi
    SHELTER_RESULTS[$i]=$result
    shelter_message success tool_complete "$name" "$SHELTER_VERSION"
  done
  shelter_results
  shelter_section shell_configuration
  [[ ${#SHELTER_PATHS[@]} == 0 ]] || SHELTER_SETTINGS_ATTEMPTED=1
  shelter_save_paths || { shelter_error shell_config_failed; return 1; }
  if [[ ${#SHELTER_PATHS[@]} -gt 0 ]]; then
    shelter_message warning paths_saved
    shelter_print activate_paths "$SHELTER_ENV_FILE"
    shelter_print restart_guidance
  else
    shelter_message success paths_unchanged
  fi
  shelter_section installation_complete success
  shelter_print all_tools_verified
  shelter_print check_scope
  shelter_print identity_guidance
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'shelter_print interrupted >&2; exit 130' INT
  shelter_main "$@"
  exit $?
fi
