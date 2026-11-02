#!/bin/bash
# English copy and terminal presentation shared by the installer and its tests.
# Display defaults and functions only: no environment checks or installation.

SHELTER_DEFAULT_COLOR=always

shelter_copy() {
  local key=${1:-} template
  [[ $# -eq 0 ]] || shift
  case "$key" in
    option_value_required) template='A value is required for %s.' ;;
    invalid_color) template='--color must be auto, always, or never.' ;;
    conflicting_actions) template='--check and --dry-run cannot be combined.' ;;
    unknown_option) template='Unknown option: %s' ;;
    build_failed) template='Could not build the Shelter Lite distribution file.' ;;
    build_complete) template='Created: %s' ;;
    build_checksum) template='SHA-256 checksum: %s' ;;
    product_version) template='Shelter Lite %s' ;;
    version_invalid) template='Could not read a valid Semantic Version such as 0.1.0 or 0.2.0-rc.1 from: %s' ;;
    release_version_mismatch) template='Release tag %s does not match expected tag %s from VERSION.' ;;
    command_finish) template='Press Return to finish. You can then close this window.' ;;
    full_unavailable) template='The full version is not available yet. Use Lite instead.' ;;
    invalid_mode) template='The supported mode is lite.' ;;
    status_changed) template='The status of %s changed: %s' ;;
    install_failed) template='Installation or verification failed for %s' ;;
    shell_config_failed) template='The tools are installed, but shell configuration failed.' ;;
    macos_only) template='This installer supports macOS only.' ;;
    os_version_unknown) template='Could not determine the macOS version.' ;;
    unsupported_platform) template='Initial support covers macOS 15 or later on Apple Silicon. Intel and Rosetta have not been verified.' ;;
    rosetta_unsupported) template='Use a native Apple Silicon terminal instead of Rosetta.' ;;
    root_unsupported) template='Run as a regular user without sudo.' ;;
    home_unknown) template='Could not determine the user home directory.' ;;
    shell_unsupported) template='Shell configuration currently supports zsh and bash.' ;;
    brew_run_failed) template='The existing Homebrew installation could not run.' ;;
    brew_path_invalid) template='The Homebrew path is invalid.' ;;
    brew_verification_failed) template='Could not verify the Homebrew installation.' ;;
    env_not_regular) template='The environment file is not a regular file.' ;;
    env_overwrite_refused) template='Cannot overwrite the existing file: %s' ;;
    symlink_target_missing) template='The symlink target does not exist: %s' ;;
    rc_not_regular) template='The shell configuration is not a regular file: %s' ;;
    check_config_permissions) template='Check access permissions for the configuration directory, then try again.' ;;
    no_rollback) template='Installation and configuration changes already made are not rolled back automatically.' ;;
    retry_guidance) template='Check the detailed log, resolve the issue, then run the installer again.' ;;
    log_path) template='Detailed log: %s' ;;
    existing_kept) template='Existing installation kept: %s — %s' ;;
    installing) template='Installing %s' ;;
    tool_complete) template='Installation complete for %s — %s' ;;
    paths_saved) template='Path settings were saved but are not active in the current terminal yet.' ;;
    paths_unchanged) template='No executable paths need to be added.' ;;
    log_creation_failed) template='Could not create the installation log.' ;;
    dry_run) template='Dry run' ;;
    status_check) template='Status check' ;;
    installation_mode) template='Installation mode' ;;
    dry_run_complete) template='Dry run complete' ;;
    installation_progress) template='Installation progress' ;;
    shell_configuration) template='Shell configuration' ;;
    installation_complete) template='Installation complete' ;;
    platform_banner) template='Shelter Lite %s — macOS %s / %s' ;;
    dry_run_intro) template='No actual installation or configuration changes will be made.' ;;
    check_intro) template='Checking the current installation status only.' ;;
    install_intro) template='Starting setup for the entire fixed tool set.' ;;
    dry_run_summary) template='Actual installations: 0, configuration changes: 0.' ;;
    installer_log_start) template='--- Installer log start: %s ---' ;;
    installer_log_end) template='--- Installer log end: %s ---' ;;
    verification_details) template='Verification details: %s' ;;
    partial_install_remains) template='Completed installations and partially installed components remain. Resolve the error and retry the same command.' ;;
    activate_paths) template='To activate the paths in the current terminal, run:\n  source %q' ;;
    restart_guidance) template='Also check in a new terminal. Restart running programs to use the new environment.' ;;
    all_tools_verified) template='All Lite tools have been verified.' ;;
    check_scope) template='Use --check to inspect versions and executable paths. It does not check security vulnerabilities or whether versions are current.' ;;
    identity_guidance) template='Configure your Git identity and GitHub login separately.' ;;
    env_backup) template='Environment file backup: %s' ;;
    rc_backup) template='Shell configuration backup: %s -> %s' ;;
    interrupted) template='\nInterrupted. Completed installations are preserved.' ;;
    command_missing) template='%s not found' ;;
    not_installed) template='Not installed' ;;
    execution_check_failed) template='Execution check failed' ;;
    command_failed) template='%s failed to run (%s)' ;;
    user_python_missing) template='User Python not found' ;;
    user_python_missing_detail) template='User Python not found (macOS developer tools Python is preserved separately)' ;;
    python_lookup_failed) template='Python lookup failed' ;;
    python_lookup_failed_detail) template='uv could not locate Python. Check the existing installation and access permissions.' ;;
    brew_missing) template='Homebrew not found' ;;
    vscode_missing) template='VS Code app not found' ;;
    ghostty_missing) template='Ghostty app not found' ;;
    ghostty_invalid) template='Ghostty app found, but its executable is missing or not executable: %s' ;;
    current_status) template='Current status' ;;
    before_installation) template='Before installation' ;;
    not_checked) template='Not checked after execution' ;;
    check_complete) template='Check complete' ;;
    check_required) template='Check required' ;;
    check_complete_summary) template='All tools can run. No installation or configuration changes were made.' ;;
    check_required_summary) template='Some tools are missing or failed to run. No installation or configuration changes were made.' ;;
    brew_needs_attention) template='Homebrew needs attention: %s' ;;
    brew_bootstrap_warning) template='An actual installation runs the official Homebrew installer. Administrator authentication and developer tools may be required.' ;;
    planned_installations) template='Planned installations' ;;
    missing_only) template='Only missing components will be installed.' ;;
    nothing_to_install) template='\nNo new tools need to be installed.' ;;
    planned_configuration) template='Planned configuration' ;;
    configuration_plan) template='Save the required executable paths and load them from the shell configuration. Back up existing files before changing them.' ;;
    env_path) template="$(shelter_icon file_code) Environment file: %s" ;;
    rc_path) template="$(shelter_icon terminal) Shell configuration: %s" ;;
    existing_install_blocked) template='Some tools fail to run, or Node.js/npm is only partially installed. Repair the existing installation first.' ;;
    installation_results) template='Installation results' ;;
    installation_failed) template='Installation failed' ;;
    setup_starting) template='Starting Shelter Lite setup.' ;;
    reopen_terminal) template='New executable paths are not active in this terminal yet. Reopen your terminal and editor to use them.' ;;
    tools_ready) template='Your development tools are ready.' ;;
    setup_failed) template='Could not complete the installation.' ;;
    unknown_notice) template='Unknown message state: %s' ;;
    unknown_icon) template='Unknown icon: %s' ;;
    result_failed) template='Failed' ;;
    result_not_run) template='Not run' ;;
    result_kept) template='Existing installation kept' ;;
    result_installed) template='New installation complete' ;;
    result_completed) template='Missing components installed' ;;
    status_ready) template='Installed' ;;
    status_blocked) template='Check required' ;;
    status_partial) template='Partially installed' ;;
    status_missing) template='Not installed' ;;
    action_ready) template='Keep the existing installation' ;;
    action_blocked) template='Repair the existing environment' ;;
    action_partial) template='Install missing components' ;;
    action_missing) template='Install new' ;;
    test_conflicting_modes) template='Run either a message preview or an installation workflow test at a time.' ;;
    test_invalid_scenario) template='Preview states: notification, warning, failure, success\nInstallation test scenarios: success, failure, dry-run' ;;
    test_invalid_color) template='Supported color modes: auto, always, never' ;;
    test_unknown_option) template='Unknown test option: %s' ;;
    test_missing) template='Missing: %s' ;;
    test_unexpected) template='Unexpected: %s' ;;
    test_preview) template='Message preview: %s (no actual installation)' ;;
    test_install_intro) template='Installation workflow test: running in a temporary environment. No actual PC installation; temporary files are cleaned up automatically.' ;;
    test_exit_mismatch) template='Test error: expected exit code %s, got %s' ;;
    test_pass) template='PASS %s' ;;
    test_fail) template='FAIL %s' ;;
    test_summary) template='\n%s passed, %s failed' ;;
    test_brew_log) template='Homebrew test log: %s' ;;
    test_brew_error) template='Homebrew test error: installation failed for %s' ;;
    test_uv_log) template='uv test log: install Python %s' ;;
    test_brew_bootstrap) template='Homebrew initial installation notice (test)' ;;
    *)
      printf -v template 'Unknown message key: %s' "$key"
      shelter_render_message error "$template" >&2
      return 2 ;;
  esac
  printf -- "$template" "$@"
}

# Message templates receive data as printf arguments, never as shell code.
# Resolving/printing an error does not decide whether installation should stop.
shelter_print() {
  local text
  text=$(shelter_copy "$@") || return
  printf '%s\n' "$text"
}

shelter_text() {
  local tone=$1 text=$2 color='' mode=${SHELTER_COLOR:-$SHELTER_DEFAULT_COLOR}
  # Installation logs explicitly use never; auto follows terminal preferences.
  if [[ "$mode" == always ]] || \
    [[ "$mode" == auto && -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
    case "$tone" in
      success) color=$'\033[1;32m' ;;
      warning) color=$'\033[1;33m' ;;
      error) color=$'\033[1;31m' ;;
      *) color=$'\033[1;36m' ;;
    esac
    printf '%s%s\033[0m' "$color" "$text"
  else
    printf '%s' "$text"
  fi
}

shelter_icon() {
  # Font Awesome PUA mappings from Nerd Fonts v3.5.0:
  # https://github.com/ryanoasis/nerd-fonts/blob/v3.5.0/glyphnames.json
  case "$1" in
    flask) printf '' ;;                 # U+F0C3
    play) printf '' ;;                  # U+F04B
    list_check) printf '' ;;            # U+F0AE
    list) printf '' ;;                  # U+F03A
    magnifying_glass) printf '' ;;       # U+F002
    gear) printf '' ;;                  # U+F013
    download) printf '' ;;              # U+F019
    file_code) printf '' ;;             # U+F1C9
    terminal) printf '' ;;              # U+F120
    check) printf '' ;;                 # U+F00C
    circle_xmark) printf '' ;;          # U+F05C
    triangle_exclamation) printf '' ;;  # U+F071
    circle_info) printf '' ;;           # U+F05A
    *) shelter_error unknown_icon "$1"; return 2 ;;
  esac
}

shelter_section() {
  local title tone=${2:-info} icon
  title=$(shelter_copy "$1") || return
  case "$1" in
    dry_run) icon=flask ;;
    status_check) icon=magnifying_glass ;;
    current_status|before_installation|installation_results) icon=list_check ;;
    installation_mode) icon=play ;;
    planned_installations|installation_progress) icon=download ;;
    planned_configuration|shell_configuration) icon=gear ;;
    dry_run_complete|check_complete|installation_complete) icon=check ;;
    installation_failed) icon=circle_xmark ;;
    check_required) icon=triangle_exclamation ;;
    *) icon=circle_info ;;
  esac
  title="$(shelter_icon "$icon") $title"
  printf '\n'
  case "$tone" in
    success|warning|error) shelter_text "$tone" "$title" ;;
    *) printf '%s' "$title" ;;
  esac
  printf '\n'
}

# Render already-resolved text; callers normally use shelter_message instead.
shelter_render_message() {
  local tone=$1 prefix=$1
  case "$tone" in
    success|warning|error) ;;
    *) prefix=note ;;
  esac
  shelter_text "$tone" '●'
  printf ' %s: %s\n' "$prefix" "$2"
}

shelter_message() {
  local tone=$1 text
  shift
  text=$(shelter_copy "$@") || return
  shelter_render_message "$tone" "$text"
}

shelter_error() {
  local text
  text=$(shelter_copy "$@") || return
  SHELTER_FAILURE_MESSAGE=$text
  shelter_render_message error "$text" >&2
}

# Shared by the real installer and message-only previews.
shelter_notice() {
  local state=$1
  shift
  case "$state" in
    notification) shelter_message info setup_starting ;;
    warning) shelter_message warning reopen_terminal ;;
    success)
      shelter_section installation_complete success
      shelter_message success tools_ready ;;
    failure)
      shelter_section installation_failed error
      if [[ $# -gt 0 ]]; then
        shelter_message error "$@"
      elif [[ -n "${SHELTER_FAILURE_MESSAGE:-}" ]]; then
        shelter_render_message error "$SHELTER_FAILURE_MESSAGE"
      else
        shelter_message error setup_failed
      fi ;;
    *) shelter_error unknown_notice "$state"; return 2 ;;
  esac
}

shelter_tool_name() {
  case "$1" in
    brew) printf 'Homebrew' ;;
    git) printf 'Git' ;;
    vscode) printf 'VS Code' ;;
    ghostty) printf 'Ghostty' ;;
    node) printf 'Node.js + npm' ;;
    python) printf 'Python + uv' ;;
    gh) printf 'GitHub CLI' ;;
  esac
}

shelter_plan_heading() {
  if [[ "$1" == check ]]; then
    shelter_section current_status
    printf '%s Tool | Status | Observed version and executable path\n\n' "$(shelter_icon list)"
  else
    shelter_section before_installation
    printf '%s Tool | Current status | Planned action\n\n' "$(shelter_icon list)"
  fi
}

shelter_plan_row() {
  local tool=$1 state=$2 action=$3 detail=$4 version=$5 tone row status
  case "$state" in
    ready) tone=success ;;
    blocked) tone=error ;;
    *) tone=warning ;;
  esac
  status=$(shelter_copy "status_$state") || return
  if [[ "$action" == check ]]; then
    printf -v row '  %-16s | %s | %s' "$(shelter_tool_name "$tool")" "$status" "$detail"
  else
    printf -v row '  %-16s | %s (%s) | %s' "$(shelter_tool_name "$tool")" "$status" "$version" "$(shelter_copy "action_$state")"
  fi
  shelter_text "$tone" '●'
  printf '%s\n' "$row"
}

shelter_results() {
  local i tone row result
  shelter_section installation_results
  printf '%s Tool | Result | Before installation → Verified result\n\n' "$(shelter_icon list)"
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    case "${SHELTER_RESULTS[$i]}" in
      failed) tone=error ;;
      not_run) tone=warning ;;
      *) tone=success ;;
    esac
    result=$(shelter_copy "result_${SHELTER_RESULTS[$i]}") || return
    printf -v row '  %-16s | %s | %s → %s' "$(shelter_tool_name "${SHELTER_TOOLS[$i]}")" \
      "$result" "${SHELTER_BEFORE[$i]}" "${SHELTER_AFTER[$i]}"
    shelter_text "$tone" '●'
    printf '%s\n' "$row"
  done
}

shelter_describe_install() {
  printf '%s ' "$(shelter_icon download)"
  case "$1" in
    brew) printf 'Homebrew: official initial installer\n' ;;
    git) printf 'Git: brew install git\n' ;;
    vscode) printf 'VS Code: brew install --cask --no-binaries visual-studio-code (preserve the existing code command)\n' ;;
    ghostty) printf 'Ghostty: brew install --cask ghostty\n' ;;
    node) printf 'Node.js + npm: brew install node@24\n' ;;
    python) printf 'Python + uv: install missing uv with brew install uv, missing Python with uv python install 3.14\n' ;;
    gh) printf 'GitHub CLI: brew install gh\n' ;;
  esac
}

shelter_logo() {
  cat <<'LOGO'
  ____  _          _ _              _     _ _
 / ___|| |__   ___| | |_ ___ _ __   | |   (_) |_ ___
 \___ \| '_ \ / _ \ | __/ _ \ '__|  | |   | | __/ _ \
  ___) | | | |  __/ | ||  __/ |     | |___| | ||  __/
 |____/|_| |_|\___|_|\__\___|_|     |_____|_|\__\___|

LOGO
}

shelter_help() {
  printf 'Shelter Lite %s — A shelter for your environment\n\n' "$SHELTER_RELEASE_VERSION"
  printf 'Usage: /bin/bash %q [options]\n' "${SHELTER_ENTRY_PATH:-installers/macos/install.sh}"
  cat <<'HELP'

  --check         Check installed tools only. Exit 1 if any tool is missing or fails
  -V, --version   Show the Shelter Lite version without changing the environment
  --dry-run       Show the installation plan. No downloads or configuration changes
  --mode lite     Lite version (default). full is not available yet
  --color [MODE]  Colors: always (default), auto (terminal settings), never (off)
                  Omit MODE to force colors for this run
  -h, --help      Show help

Without options, prepare the entire fixed tool set in order. There is no tool selection menu.
Homebrew → Git → VS Code → Ghostty → Node.js/npm → Python/uv → GitHub CLI
Supported: macOS 15 or later, Apple Silicon, zsh/bash. Do not run with sudo.
Skip existing tools that run successfully. Homebrew handles dependencies for new packages.
New installations use Node.js 24 and Python 3.14 managed by uv.
The default output shows the final result and brief guidance, with warnings when needed.
Details are saved in logs/ under the configuration directory.
HELP
}

shelter_build_help() {
  cat <<'HELP'
Usage: /bin/bash installers/macos/build.sh [--output-dir DIR]

Build a standalone Shelter Lite script, a double-click ZIP, and SHA-256 checksums.
The default output directory is dist/ at the repository root.
No programs are downloaded or installed during the build.
HELP
}

shelter_test_help() {
  cat <<'HELP'
Usage: /bin/bash installers/macos/tests/test.sh [options]

  No options                   Run the full automated test suite
  --preview [state]             Show only the selected message (default: success)
    notification               Notice, cyan ●
    warning                    Caution and next steps, yellow ●
    failure                    Failure and reason, red ● and result heading
    success                    Completion and result, green ● and result heading
  --install [scenario]          Run the full installer in a temporary environment
    success                    Complete installation workflow (default)
    failure                    Verify failure and stop during uv installation
    dry-run                    Show the installation plan
  --color [MODE]               always (default), auto (terminal settings), never (off)
                               Omit MODE to force colors for this run

--intall is an alias for --install. Tests do not install programs on your actual computer.
Set SHELTER_TEST_INSTALLER to a standalone installer path to test the bundled code.
HELP
}
