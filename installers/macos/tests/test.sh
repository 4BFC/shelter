#!/bin/bash
# Dependency-free Bash 3.2 tests. All installations and configuration writes use
# disposable fixtures; HOME and the user's actual package managers are untouched.

TEST_SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P) || exit 1
source "${SHELTER_TEST_INSTALLER:-$TEST_SOURCE_DIR/install.sh}" || exit 1
TEST_MODE=suite
TEST_SCENARIO=success
TEST_COLOR=$SHELTER_DEFAULT_COLOR
while [[ $# -gt 0 ]]; do
  case "$1" in
    --preview|--install|--intall)
      [[ "$TEST_MODE" == suite ]] || { shelter_print test_conflicting_modes >&2; exit 2; }
      case "$1" in --preview) TEST_MODE=preview ;; *) TEST_MODE=install ;; esac
      if [[ $# -gt 1 && "$2" != --* ]]; then TEST_SCENARIO=$2; shift; fi
      case "$TEST_MODE:$TEST_SCENARIO" in
        preview:notification|preview:warning|preview:failure|preview:success|install:success|install:failure|install:dry-run) ;;
        *) shelter_print test_invalid_scenario >&2; exit 2 ;;
      esac ;;
    --color)
      TEST_COLOR=always
      if [[ $# -gt 1 && "$2" != -* ]]; then
        case "$2" in auto|always|never) TEST_COLOR=$2 ;; *) shelter_print test_invalid_color >&2; exit 2 ;; esac
        shift
      fi ;;
    --help|-h)
      shelter_test_help
      exit 0 ;;
    *) shelter_print test_unknown_option "$1" >&2; exit 2 ;;
  esac
  shift
done
TEST_PASSED=0
TEST_FAILED=0

assert_contains() { grep -Fq -- "$2" "$1" || { shelter_print test_missing "$2"; return 1; }; }
assert_absent() { ! grep -Fq -- "$2" "$1" || { shelter_print test_unexpected "$2"; return 1; }; }
assert_empty_log() { [[ ! -s "$SHELTER_FAKE_LOG" ]]; }

setup_fixture() {
  SHELTER_CASE_DIR="$SHELTER_TEST_ROOT/$1 with spaces"
  export SHELTER_FAKE_PREFIX="$SHELTER_CASE_DIR/brew"
  export SHELTER_FAKE_PY_BIN="$SHELTER_CASE_DIR/python-bin"
  export SHELTER_FAKE_GHOSTTY_APP="$SHELTER_CASE_DIR/Applications/Ghostty.app"
  export SHELTER_FAKE_DRIVER="$SHELTER_CASE_DIR/driver"
  export SHELTER_FAKE_MESSAGES="$TEST_SOURCE_DIR/messages.sh"
  export SHELTER_FAKE_LOG="$SHELTER_CASE_DIR/actions.log"
  export SHELTER_FAKE_FAIL='' SHELTER_FAKE_BROKEN='' SHELTER_FAKE_NODE_VERSION=v24.22.2
  export SHELTER_FAKE_SHOW_LOG=0
  export SHELTER_FAKE_PYTHON_LOOKUP_ERROR=0
  export TMPDIR="$SHELTER_CASE_DIR/tmp"
  mkdir -p "$SHELTER_CASE_DIR/bin" "$TMPDIR" || return 1
  : > "$SHELTER_FAKE_LOG"
  TEST_INITIAL_PATH="$SHELTER_CASE_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  export PATH="$TEST_INITIAL_PATH"
  hash -r
  cat > "$SHELTER_FAKE_DRIVER" <<'FAKE'
#!/bin/bash
source "$SHELTER_FAKE_MESSAGES" || exit 1
make_tool() {
  local name=$1 target="$SHELTER_FAKE_PREFIX/bin/$1"
  case "$name" in
    node|npm) target="$SHELTER_FAKE_PREFIX/opt/node@24/bin/$name" ;;
    python3.14) target="$SHELTER_FAKE_PY_BIN/$name" ;;
    ghostty) target="$SHELTER_FAKE_GHOSTTY_APP/Contents/MacOS/ghostty" ;;
  esac
  mkdir -p "${target%/*}" || exit 1
  cp "$SHELTER_FAKE_DRIVER" "$target" || exit 1
  chmod +x "$target" || exit 1
}
name=${0##*/}
if [[ "$name" == driver ]]; then make_tool "$2"; exit $?; fi
if [[ "$1" == --version ]]; then
  [[ "$SHELTER_FAKE_BROKEN" != "$name" ]] || exit 1
  [[ "$name" != code ]] || printf 'fixture stderr warning\n' >&2
  case "$name" in
    node) printf '%s\n' "$SHELTER_FAKE_NODE_VERSION" ;;
    npm) printf '11.0.0\n' ;;
    python*) printf 'Python 3.14.0\n' ;;
    ghostty) printf 'Ghostty 1.0.0\n\nBuild Config\n  - fixture\n' ;;
    *) printf '%s fixture-version\n' "$name" ;;
  esac
  exit 0
fi
if [[ "$name" == brew ]]; then
  case "$1" in
    --prefix) printf '%s\n' "$SHELTER_FAKE_PREFIX" ;;
    install)
      [[ "$HOMEBREW_NO_AUTO_UPDATE" == 1 && "$HOMEBREW_NO_INSTALL_CLEANUP" == 1 && "$HOMEBREW_NO_INSTALL_UPGRADE" == 1 ]] || exit 91
      shift
      printf 'brew install %s\n' "$*" >> "$SHELTER_FAKE_LOG"
      [[ "$SHELTER_FAKE_SHOW_LOG" != 1 ]] || shelter_print test_brew_log "$*"
      [[ "$SHELTER_FAKE_FAIL" != "${@: -1}" ]] || { shelter_print test_brew_error "${@: -1}" >&2; exit 1; }
      case "$1" in
        node@24) make_tool node; make_tool npm ;;
        --cask)
          case "${@: -1}" in
            visual-studio-code) make_tool code ;;
            ghostty) make_tool ghostty ;;
            *) exit 90 ;;
          esac ;;
        *) make_tool "$1" ;;
      esac ;;
    *) exit 90 ;;
  esac
elif [[ "$name" == uv ]]; then
  no_cache=0
  offline=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-config) shift ;;
      --no-cache) no_cache=1; shift ;;
      --offline) offline=1; shift ;;
      *) break ;;
    esac
  done
  case "$1 $2" in
    'python dir') printf '%s\n' "$SHELTER_FAKE_PY_BIN" ;;
    'python find')
      [[ $no_cache == 1 && $offline == 1 && "$SHELTER_FAKE_PYTHON_LOOKUP_ERROR" == 0 ]] || exit 2
      [[ -x "$SHELTER_FAKE_PY_BIN/python3.14" ]] || exit 1
      printf '%s\n' "$SHELTER_FAKE_PY_BIN/python3.14" ;;
    'python list')
      [[ $no_cache == 1 && $offline == 1 && "$SHELTER_FAKE_PYTHON_LOOKUP_ERROR" == 0 ]] || exit 2
      if [[ -x "$SHELTER_FAKE_PY_BIN/python3.14" ]]; then
        printf 'cpython-3.14 %s\n' "$SHELTER_FAKE_PY_BIN/python3.14"
      fi ;;
    'python install')
      printf 'uv python install %s\n' "$3" >> "$SHELTER_FAKE_LOG"
      [[ "$SHELTER_FAKE_SHOW_LOG" != 1 ]] || shelter_print test_uv_log "$3"
      [[ "$SHELTER_FAKE_FAIL" != python ]] || exit 1
      make_tool python3.14 ;;
    *) exit 90 ;;
  esac
else
  exit 90
fi
FAKE
  chmod +x "$SHELTER_FAKE_DRIVER"
  uname() { case "$1" in -s) printf 'Darwin\n' ;; -m) printf 'arm64\n' ;; *) return 1 ;; esac; }
  sw_vers() { printf '15.0\n'; }
  sysctl() { printf '0\n'; }
  id() { printf '501\n'; }
  xcode-select() { return 1; }
  shelter_find_brew() {
    [[ -x "$SHELTER_FAKE_PREFIX/bin/brew" ]] || return 1
    printf '%s\n' "$SHELTER_FAKE_PREFIX/bin/brew"
  }
  # Do not discover or change the real /Applications or user configuration.
  shelter_find_vscode() {
    [[ -x "$SHELTER_FAKE_PREFIX/bin/code" ]] || return 1
    printf '%s\n' "$SHELTER_FAKE_PREFIX/bin/code"
  }
  shelter_find_ghostty() {
    [[ -e "$SHELTER_FAKE_GHOSTTY_APP" || -L "$SHELTER_FAKE_GHOSTTY_APP" ]] || return 1
    printf '%s/Contents/MacOS/ghostty\n' "$SHELTER_FAKE_GHOSTTY_APP"
  }
  shelter_shell_targets() {
    SHELTER_ENV_FILE="$SHELTER_CASE_DIR/config/env.sh"
    SHELTER_RC_FILES=("$SHELTER_CASE_DIR/zshrc")
  }
  curl() {
    local output=''
    printf 'download brew\n' >> "$SHELTER_FAKE_LOG"
    [[ "$SHELTER_FAKE_FAIL" != download ]] || return 22
    while [[ $# -gt 0 ]]; do
      if [[ "$1" == -o ]]; then output=$2; break; fi
      shift
    done
    [[ -n "$output" ]] || return 90
    cat > "$output" <<'BOOTSTRAP'
#!/bin/bash
source "$SHELTER_FAKE_MESSAGES" || exit 1
shelter_print test_brew_bootstrap
"$SHELTER_FAKE_DRIVER" create brew
BOOTSTRAP
  }
}

test_preview() {
  shelter_main --dry-run > "$SHELTER_CASE_DIR/output" || return 1
  assert_empty_log || return 1
  [[ ! -e "$SHELTER_CASE_DIR/config" ]] || return 1
  local tool
  for tool in Homebrew Git 'VS Code' Ghostty 'Node.js + npm' 'Python + uv' 'GitHub CLI'; do
    assert_contains "$SHELTER_CASE_DIR/output" "$tool" || return 1
  done
  grep -Fxq -- ' Dry run' "$SHELTER_CASE_DIR/output" || return 1
  grep -Fxq -- ' Before installation' "$SHELTER_CASE_DIR/output" || return 1
  grep -Fxq -- ' Tool | Current status | Planned action' "$SHELTER_CASE_DIR/output" || return 1
  grep -Fxq -- " Environment file: $SHELTER_ENV_FILE" "$SHELTER_CASE_DIR/output" || return 1
  grep -Fxq -- " Shell configuration: ${SHELTER_RC_FILES[0]}" "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'No actual installation or configuration changes will be made.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Install new' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Ghostty: brew install --cask ghostty' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Dry run complete' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Actual installations: 0, configuration changes: 0' || return 1
  [[ $(grep -Fc ' / ___|| |__' "$SHELTER_CASE_DIR/output") == 1 ]] || return 1
  assert_absent "$SHELTER_CASE_DIR/output" ' Installation progress' && assert_absent "$SHELTER_CASE_DIR/output" ' Installation results'
}

test_check_missing() {
  shelter_main --check > "$SHELTER_CASE_DIR/output"
  [[ $? == 1 ]] && assert_empty_log && [[ ! -e "$SHELTER_CASE_DIR/config" ]]
}

test_full_unavailable() {
  shelter_main --mode full > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 2 ]] && assert_contains "$SHELTER_CASE_DIR/output" 'The full version is not available yet' && assert_empty_log
}

test_options() {
  local status
  shelter_main --tools git > /dev/null 2>&1; status=$?
  [[ $status == 2 ]] || return 1
  shelter_main --mode > /dev/null 2>&1; status=$?
  [[ $status == 2 ]] || return 1
  shelter_main --check --dry-run > /dev/null 2>&1; status=$?
  [[ $status == 2 ]] && assert_empty_log
}

test_platforms() {
  uname() { printf 'Linux\n'; }
  shelter_main --dry-run > /dev/null 2>&1; [[ $? == 2 ]] || return 1
  uname() { case "$1" in -s) printf 'Darwin\n' ;; -m) printf 'x86_64\n' ;; esac; }
  shelter_main --dry-run > /dev/null 2>&1; [[ $? == 2 ]] || return 1
  uname() { case "$1" in -s) printf 'Darwin\n' ;; -m) printf 'arm64\n' ;; esac; }
  sw_vers() { printf '14.0\n'; }
  shelter_main --dry-run > /dev/null 2>&1; [[ $? == 2 ]] || return 1
  sw_vers() { printf '15.0\n'; }
  sysctl() { printf '1\n'; }
  shelter_main --dry-run > /dev/null 2>&1; [[ $? == 2 ]] || return 1
  sysctl() { printf '0\n'; }
  id() { printf '0\n'; }
  shelter_main --dry-run > /dev/null 2>&1; [[ $? == 2 ]] || return 1
  shelter_main --help > /dev/null || return 1
  assert_empty_log
}

test_fresh_and_repeat() {
  printf '# original settings\n' > "$SHELTER_CASE_DIR/zshrc"
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  cat > "$SHELTER_CASE_DIR/expected" <<'EXPECTED'
download brew
brew install git
brew install --cask --no-binaries visual-studio-code
brew install --cask ghostty
brew install node@24
brew install uv
uv python install 3.14
brew install gh
EXPECTED
  diff -u "$SHELTER_CASE_DIR/expected" "$SHELTER_FAKE_LOG" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Homebrew initial installation notice (test)' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" 'fixture stderr warning' || return 1
  assert_contains "$SHELTER_CASE_DIR/zshrc" '# original settings' || return 1
  assert_contains "$SHELTER_CASE_DIR/zshrc" '# Shelter Lite' || return 1
  /bin/bash -n "$SHELTER_ENV_FILE" || return 1
  # Verify the generated PATH configuration, including spaces, in a fresh shell.
  PATH="$TEST_INITIAL_PATH" /bin/bash -c '. "$1"; node --version && npm --version && python3.14 --version && code --version' bash "$SHELTER_ENV_FILE" || return 1
  if [[ -x /bin/zsh ]]; then
    PATH="$TEST_INITIAL_PATH" /bin/zsh -f -c '. "$1"; node --version && python3.14 --version' zsh "$SHELTER_ENV_FILE" || return 1
  fi
  export PATH="$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/repeat" || return 1
  cmp "$SHELTER_CASE_DIR/expected" "$SHELTER_FAKE_LOG" || return 1
  [[ $(grep -c '# Shelter Lite' "$SHELTER_CASE_DIR/zshrc") == 1 ]] || return 1
  shelter_main --check > /dev/null || return 1
}

test_existing_node() {
  "$SHELTER_FAKE_DRIVER" create node
  "$SHELTER_FAKE_DRIVER" create npm
  export SHELTER_FAKE_NODE_VERSION=v22.0.0
  PATH="$SHELTER_FAKE_PREFIX/opt/node@24/bin:$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_LOG_FILE" 'v22.0.0' && assert_absent "$SHELTER_FAKE_LOG" 'install node@24'
}

test_existing_ghostty() {
  "$SHELTER_FAKE_DRIVER" create ghostty || return 1
  command -v ghostty >/dev/null 2>&1 && return 1
  shelter_main --dry-run --color never > "$SHELTER_CASE_DIR/plan" || return 1
  assert_contains "$SHELTER_CASE_DIR/plan" 'Ghostty          | Installed (Ghostty 1.0.0) | Keep the existing installation' || return 1
  assert_empty_log || return 1
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Ghostty          | Existing installation kept | Ghostty 1.0.0 → Ghostty 1.0.0' || return 1
  assert_absent "$SHELTER_FAKE_LOG" 'brew install --cask ghostty' || return 1
  shelter_main --check > "$SHELTER_CASE_DIR/check" || return 1
  assert_contains "$SHELTER_CASE_DIR/check" "Ghostty 1.0.0 ($SHELTER_FAKE_GHOSTTY_APP/Contents/MacOS/ghostty)"
}

test_broken_ghostty() {
  mkdir -p "$SHELTER_FAKE_GHOSTTY_APP"
  shelter_main --check > "$SHELTER_CASE_DIR/missing-binary" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/missing-binary" 'Ghostty app found, but its executable is missing or not executable' || return 1
  "$SHELTER_FAKE_DRIVER" create ghostty || return 1
  chmod -x "$SHELTER_FAKE_GHOSTTY_APP/Contents/MacOS/ghostty"
  shelter_main --check > "$SHELTER_CASE_DIR/not-executable" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/not-executable" 'Ghostty app found, but its executable is missing or not executable' || return 1
  chmod +x "$SHELTER_FAKE_GHOSTTY_APP/Contents/MacOS/ghostty"
  export SHELTER_FAKE_BROKEN=ghostty
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Repair the existing environment' && assert_empty_log
}

test_ghostty_failure_and_retry() {
  export SHELTER_FAKE_FAIL=ghostty
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Installation or verification failed for Ghostty' || return 1
  assert_absent "$SHELTER_FAKE_LOG" 'brew install node@24' || return 1
  export SHELTER_FAKE_FAIL=''
  shelter_main > "$SHELTER_CASE_DIR/retry" || return 1
  [[ $(grep -c 'brew install --cask ghostty' "$SHELTER_FAKE_LOG") == 2 ]] || return 1
  [[ $(grep -c 'brew install --cask --no-binaries visual-studio-code' "$SHELTER_FAKE_LOG") == 1 ]]
}

test_ghostty_verification_failure() {
  export SHELTER_FAKE_BROKEN=ghostty
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_FAKE_LOG" 'brew install --cask ghostty' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Installation or verification failed for Ghostty' || return 1
  assert_absent "$SHELTER_FAKE_LOG" 'brew install node@24'
}

test_partial_node() {
  "$SHELTER_FAKE_DRIVER" create node
  PATH="$SHELTER_FAKE_PREFIX/opt/node@24/bin:$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_LOG_FILE" 'Repair the existing environment' && assert_empty_log
}

test_install_failure_and_retry() {
  export SHELTER_FAKE_FAIL=uv
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  [[ -x "$SHELTER_FAKE_PREFIX/opt/node@24/bin/node" ]] || return 1
  assert_absent "$SHELTER_FAKE_LOG" 'brew install gh' || return 1
  export SHELTER_FAKE_FAIL=''
  PATH="$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/retry" || return 1
  [[ $(grep -c 'brew install node@24' "$SHELTER_FAKE_LOG") == 1 ]]
}

test_download_failure() {
  export SHELTER_FAKE_FAIL=download
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  [[ ! -e "$SHELTER_FAKE_PREFIX/bin/brew" && ! -e "$SHELTER_CASE_DIR/config/env.sh" && -f "$SHELTER_LOG_FILE" ]] || return 1
  [[ -z $(ls -A "$TMPDIR") ]]
}

test_verification_failure() {
  export SHELTER_FAKE_BROKEN=gh
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" 'Installation or verification failed for GitHub CLI' && assert_absent "$SHELTER_CASE_DIR/output" 'All Lite tools have been verified.'
}

test_config_conflict() {
  mkdir -p "$SHELTER_CASE_DIR/config"
  printf '# manually maintained\n' > "$SHELTER_CASE_DIR/config/env.sh"
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/config/env.sh" '# manually maintained' && [[ ! -e "$SHELTER_CASE_DIR/zshrc" ]]
}

test_broken_existing() {
  "$SHELTER_FAKE_DRIVER" create brew
  "$SHELTER_FAKE_DRIVER" create git
  export SHELTER_FAKE_BROKEN=git
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_absent "$SHELTER_CASE_DIR/output" 'warning:' && assert_empty_log
}

test_config_symlink() {
  mkdir -p "$SHELTER_CASE_DIR/config"
  ln -s "$SHELTER_CASE_DIR/absent-target" "$SHELTER_CASE_DIR/config/env.sh"
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 && -L "$SHELTER_CASE_DIR/config/env.sh" && ! -e "$SHELTER_CASE_DIR/absent-target" ]]
}

test_python_existing_runtime() {
  cp "$SHELTER_FAKE_DRIVER" "$SHELTER_CASE_DIR/bin/python3"
  chmod +x "$SHELTER_CASE_DIR/bin/python3"
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Python + uv      | Missing components installed' || return 1
  assert_contains "$SHELTER_FAKE_LOG" 'brew install uv' && assert_absent "$SHELTER_FAKE_LOG" 'uv python install'
}

test_other_editor_code() {
  printf '#!/bin/bash\nprintf "Other editor 1.0\\n"\n' > "$SHELTER_CASE_DIR/bin/code"
  chmod +x "$SHELTER_CASE_DIR/bin/code"
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_FAKE_LOG" 'brew install --cask --no-binaries visual-studio-code' || return 1
  [[ $(code --version) == 'Other editor 1.0' ]]
}

test_config_append_and_backup() {
  shelter_main > /dev/null || return 1
  mkdir -p "$SHELTER_CASE_DIR/extra 'quoted' bin"
  SHELTER_PATHS=("$SHELTER_CASE_DIR/extra 'quoted' bin")
  shelter_save_paths || return 1
  /bin/bash -n "$SHELTER_ENV_FILE" || return 1
  PATH="$TEST_INITIAL_PATH" /bin/bash -c '. "$1"; case ":$PATH:" in *":$2:"*) exit 0 ;; *) exit 1 ;; esac' bash "$SHELTER_ENV_FILE" "${SHELTER_PATHS[0]}" || return 1
  local backups=("$SHELTER_CASE_DIR"/config/env.sh.backup.*)
  [[ -f "${backups[0]}" ]] && [[ $(grep -c '# Shelter Lite' "$SHELTER_CASE_DIR/zshrc") == 1 ]]
}

seed_preview_tools() {
  local tool
  for tool in brew git node npm gh; do
    "$SHELTER_FAKE_DRIVER" create "$tool" || return 1
  done
}

preview_message() {
  SHELTER_COLOR=$TEST_COLOR
  shelter_print test_preview "$1"
  case "$1" in
    failure) shelter_notice failure install_failed "$(shelter_tool_name python)" ;;
    *) shelter_notice "$1" ;;
  esac
}

run_install_test() (
  local scenario=$1 status expected=0
  setup_fixture "install-$scenario" || return 1
  export SHELTER_FAKE_SHOW_LOG=1
  shelter_print test_install_intro
  case "$scenario" in
    dry-run) shelter_main --dry-run --color "$TEST_COLOR"; status=$? ;;
    success) shelter_main --color "$TEST_COLOR"; status=$? ;;
    failure)
      export SHELTER_FAKE_FAIL=uv
      expected=1
      shelter_main --color "$TEST_COLOR"; status=$? ;;
  esac
  if [[ "$status" != "$expected" ]]; then
    shelter_print test_exit_mismatch "$expected" "$status" >&2
    return 1
  fi
)

test_success_messages() {
  seed_preview_tools || return 1
  export SHELTER_FAKE_SHOW_LOG=1
  shelter_main --color never > "$SHELTER_CASE_DIR/output" || return 1
  [[ $(grep -Fc ' / ___|| |__' "$SHELTER_CASE_DIR/output") == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Installation complete' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '------------------------------------------------------------' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● success: Your development tools are ready.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● warning: New executable paths are not active in this terminal yet.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Reopen your terminal and editor' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" ' Before installation' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" ' Installation results' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" 'test log' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" 'fixture-version' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Node.js + npm    | Existing installation kept | v24.22.2 / 11.0.0 → v24.22.2 / 11.0.0' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'VS Code          | New installation complete | Not installed → code fixture-version' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Ghostty          | New installation complete | Not installed → Ghostty 1.0.0' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Homebrew test log:' || return 1
  # Six logo lines precede the existing concise guidance.
  [[ $(wc -l < "$SHELTER_CASE_DIR/output") -le 14 ]] && [[ $(LC_ALL=C ls -ld "$SHELTER_LOG_FILE") == -rw-------* ]]
}

test_failure_messages() {
  seed_preview_tools || return 1
  export SHELTER_FAKE_FAIL=uv
  shelter_main --color never > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  [[ $(grep -Fc ' / ___|| |__' "$SHELTER_CASE_DIR/output") == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Installation failed' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● error: Installation or verification failed for Python + uv' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● warning: Installation and configuration changes already made are not rolled back automatically.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● note: Check the detailed log, resolve the issue, then run the installer again.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" "Detailed log: $SHELTER_LOG_FILE" || return 1
  assert_contains "$SHELTER_LOG_FILE" 'VS Code          | New installation complete' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Python + uv      | Failed' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'GitHub CLI       | Not run' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Homebrew test error: installation failed for uv' || return 1
  assert_contains "$SHELTER_LOG_FILE" '● error: Installation or verification failed for Python + uv' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" ' Installation complete' && ! grep -Fqx -- ' Shell configuration' "$SHELTER_CASE_DIR/output"
}

test_check_messages() {
  seed_preview_tools || return 1
  NO_COLOR=1 TERM=dumb shelter_main --check > "$SHELTER_CASE_DIR/output"
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Status check' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" ' Current status' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" "$SHELTER_FAKE_PREFIX/bin/git" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;33m Check required\033[0m' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m●\033[0m  Homebrew' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" $'\033[1;36m' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" 'Planned' && assert_absent "$SHELTER_CASE_DIR/output" ' Installation results' && assert_empty_log
}

test_preview_cli() {
  local scenario expected
  for scenario in notification warning failure success; do
    case "$scenario" in
      notification) expected=$'\033[1;36m●\033[0m note: Starting Shelter Lite setup.' ;;
      warning) expected=$'\033[1;33m●\033[0m warning: New executable paths are not active in this terminal yet. Reopen your terminal and editor to use them.' ;;
      failure) expected=$'\033[1;31m●\033[0m error: Installation or verification failed for Python + uv' ;;
      success) expected=$'\033[1;32m●\033[0m success: Your development tools are ready.' ;;
    esac
    NO_COLOR=1 TERM=dumb /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview "$scenario" > "$SHELTER_CASE_DIR/$scenario" 2>&1 || return 1
    assert_contains "$SHELTER_CASE_DIR/$scenario" "Message preview: $scenario (no actual installation)" || return 1
    # Only the dot is colored; the prefix and body remain in the terminal's default color.
    grep -Fxq -- "$expected" "$SHELTER_CASE_DIR/$scenario" || return 1
    case "$scenario" in
      failure) assert_contains "$SHELTER_CASE_DIR/$scenario" $'\033[1;31m Installation failed\033[0m' || return 1 ;;
      success) assert_contains "$SHELTER_CASE_DIR/$scenario" $'\033[1;32m Installation complete\033[0m' || return 1 ;;
    esac
    assert_absent "$SHELTER_CASE_DIR/$scenario" 'fixture-version' || return 1
    /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview "$scenario" --color never > "$SHELTER_CASE_DIR/$scenario-plain" 2>&1 || return 1
    assert_absent "$SHELTER_CASE_DIR/$scenario-plain" $'\033' || return 1
    assert_contains "$SHELTER_CASE_DIR/$scenario-plain" '● ' || return 1
  done
  NO_COLOR=1 /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview > "$SHELTER_CASE_DIR/default-preview" || return 1
  assert_contains "$SHELTER_CASE_DIR/default-preview" $'\033[1;32m●\033[0m success: Your development tools are ready.' || return 1
  NO_COLOR=1 /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview --color auto > "$SHELTER_CASE_DIR/auto-preview" || return 1
  assert_contains "$SHELTER_CASE_DIR/auto-preview" '● success: Your development tools are ready.' || return 1
  assert_absent "$SHELTER_CASE_DIR/auto-preview" $'\033' || return 1
  [[ -z $(ls -A "$TMPDIR") ]] || return 1
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview unknown > /dev/null 2>&1
  [[ $? == 2 ]] || return 1
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview --color unknown > /dev/null 2>&1
  [[ $? == 2 ]] || return 1
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview warning --install > /dev/null 2>&1
  [[ $? == 2 ]] && assert_empty_log
}

test_install_cli() {
  local scenario
  for scenario in success failure dry-run; do
    /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --install "$scenario" --color never > "$SHELTER_CASE_DIR/$scenario" 2>&1 || return 1
    assert_contains "$SHELTER_CASE_DIR/$scenario" 'Installation workflow test: running in a temporary environment.' || return 1
    assert_absent "$SHELTER_CASE_DIR/$scenario" 'Test error:' || return 1
    case "$scenario" in
      success) assert_contains "$SHELTER_CASE_DIR/$scenario" '● success: Your development tools are ready.' || return 1 ;;
      failure) assert_contains "$SHELTER_CASE_DIR/$scenario" '● error: Installation or verification failed for Python + uv' || return 1 ;;
      dry-run) assert_contains "$SHELTER_CASE_DIR/$scenario" 'Actual installations: 0, configuration changes: 0' || return 1 ;;
    esac
  done
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --intall --color never > "$SHELTER_CASE_DIR/alias" 2>&1 || return 1
  assert_contains "$SHELTER_CASE_DIR/alias" '● success: Your development tools are ready.' || return 1
  [[ -z $(ls -A "$TMPDIR") ]] || return 1
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --install unknown > /dev/null 2>&1
  [[ $? == 2 ]] && assert_empty_log
}

test_forced_color_and_plain_log() {
  seed_preview_tools || return 1
  NO_COLOR=1 TERM=dumb shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m Installation complete\033[0m' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;33m●\033[0m warning:' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;36m●\033[0m note: Starting Shelter Lite setup.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m●\033[0m success: Your development tools are ready.' || return 1
  assert_absent "$SHELTER_LOG_FILE" $'\033' || return 1
  shelter_main --color never > "$SHELTER_CASE_DIR/plain" || return 1
  assert_absent "$SHELTER_CASE_DIR/plain" $'\033' || return 1
  assert_absent "$SHELTER_CASE_DIR/plain" 'warning:' || return 1
  shelter_main --color always --unknown > "$SHELTER_CASE_DIR/invalid-stdout" 2> "$SHELTER_CASE_DIR/invalid-stderr"
  [[ $? == 2 ]] && [[ ! -s "$SHELTER_CASE_DIR/invalid-stdout" ]] && \
    assert_contains "$SHELTER_CASE_DIR/invalid-stderr" $'\033[1;31m●\033[0m error: Unknown option: --unknown'
}

test_color_flag() {
  NO_COLOR=1 TERM=dumb shelter_main --dry-run > "$SHELTER_CASE_DIR/default-color" || return 1
  NO_COLOR=1 TERM=dumb shelter_main --dry-run --color > "$SHELTER_CASE_DIR/color-last" || return 1
  cmp "$SHELTER_CASE_DIR/default-color" "$SHELTER_CASE_DIR/color-last" || return 1
  assert_contains "$SHELTER_CASE_DIR/color-last" $'\033[1;32m Dry run complete\033[0m' || return 1
  NO_COLOR=1 TERM=dumb shelter_main --color --dry-run > "$SHELTER_CASE_DIR/color-first" || return 1
  cmp "$SHELTER_CASE_DIR/color-last" "$SHELTER_CASE_DIR/color-first" || return 1
  NO_COLOR=1 shelter_main --dry-run --color auto > "$SHELTER_CASE_DIR/auto" || return 1
  assert_absent "$SHELTER_CASE_DIR/auto" $'\033' || return 1
  shelter_main --dry-run --color --color never > "$SHELTER_CASE_DIR/never" || return 1
  assert_absent "$SHELTER_CASE_DIR/never" $'\033' || return 1
  local invalid
  for invalid in unknown ''; do
    shelter_main --dry-run --color "$invalid" > /dev/null 2>&1
    [[ $? == 2 ]] || return 1
  done
  NO_COLOR=1 TERM=dumb /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --color --preview warning > "$SHELTER_CASE_DIR/preview-first" || return 1
  assert_contains "$SHELTER_CASE_DIR/preview-first" $'\033[1;33m●\033[0m warning:' || return 1
  NO_COLOR=1 /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview warning --color > "$SHELTER_CASE_DIR/preview-last" || return 1
  cmp "$SHELTER_CASE_DIR/preview-first" "$SHELTER_CASE_DIR/preview-last" || return 1
  NO_COLOR=1 TERM=dumb /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --install > "$SHELTER_CASE_DIR/install" || return 1
  assert_contains "$SHELTER_CASE_DIR/install" $'\033[1;32m Installation complete\033[0m' || return 1
  [[ ! -e "$SHELTER_CASE_DIR/config" && -z $(ls -A "$TMPDIR") ]] && assert_empty_log
}

test_log_failure_stops_install() {
  shelter_create_log() { return 1; }
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" ' Installation failed' && assert_absent "$SHELTER_CASE_DIR/output" 'warning:' && assert_empty_log
}

test_python_lookup_failure() {
  "$SHELTER_FAKE_DRIVER" create brew
  "$SHELTER_FAKE_DRIVER" create uv
  export SHELTER_FAKE_PYTHON_LOOKUP_ERROR=1
  shelter_main --dry-run > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Python lookup failed' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" ' Dry run complete' && assert_empty_log
}

test_message_catalog() {
  local payload='Package 100% \path $(literal)' expected
  SHELTER_COLOR=never
  # Sourcing the catalog alone must be silent and independent of tool setup.
  /bin/bash -c 'source "$1"' bash "$TEST_SOURCE_DIR/messages.sh" > "$SHELTER_CASE_DIR/source" 2>&1 || return 1
  [[ ! -s "$SHELTER_CASE_DIR/source" ]] || return 1
  expected="Installation or verification failed for $payload"
  [[ "$(shelter_copy install_failed "$payload")" == "$expected" ]] || return 1
  shelter_error install_failed "$payload" > "$SHELTER_CASE_DIR/stdout" 2> "$SHELTER_CASE_DIR/stderr" || return 1
  [[ ! -s "$SHELTER_CASE_DIR/stdout" && "$SHELTER_FAILURE_MESSAGE" == "$expected" ]] || return 1
  grep -Fxq -- "● error: $expected" "$SHELTER_CASE_DIR/stderr" || return 1
  # Reporting an error keeps control with the caller; the final notice reuses it.
  shelter_notice failure > "$SHELTER_CASE_DIR/failure" || return 1
  grep -Fxq -- "● error: $expected" "$SHELTER_CASE_DIR/failure" || return 1
  shelter_message info missing_message_key > "$SHELTER_CASE_DIR/unknown-out" 2> "$SHELTER_CASE_DIR/unknown-err"
  [[ $? == 2 && ! -s "$SHELTER_CASE_DIR/unknown-out" ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/unknown-err" 'Unknown message key: missing_message_key' || return 1
  # The test harness's descriptive copy shares the same source, too.
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --unknown > "$SHELTER_CASE_DIR/test-out" 2> "$SHELTER_CASE_DIR/test-err"
  [[ $? == 2 && ! -s "$SHELTER_CASE_DIR/test-out" ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/test-err" 'Unknown test option: --unknown' && assert_empty_log
}

run_test() {
  local name=$1 function=$2 output="$SHELTER_TEST_ROOT/$1.log"
  if (setup_fixture "$name" && "$function") > "$output" 2>&1; then
    shelter_print test_pass "$name"
    TEST_PASSED=$((TEST_PASSED + 1))
  else
    shelter_print test_fail "$name"
    cat "$output"
    TEST_FAILED=$((TEST_FAILED + 1))
  fi
}

if [[ "$TEST_MODE" == preview ]]; then
  preview_message "$TEST_SCENARIO"
  exit $?
fi

SHELTER_TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/shelter-tests.XXXXXX") || exit 1
trap 'rm -rf "$SHELTER_TEST_ROOT"' EXIT

if [[ "$TEST_MODE" == install ]]; then
  run_install_test "$TEST_SCENARIO"
  exit $?
fi

test_standalone_build() {
  local output_dir="$SHELTER_CASE_DIR/bundle" copied="$SHELTER_CASE_DIR/relocated setup.sh"
  local extracted="$SHELTER_CASE_DIR/unpacked with spaces" archived="$SHELTER_CASE_DIR/original.zip"
  /bin/bash "$TEST_SOURCE_DIR/build.sh" --output-dir "$output_dir" > /dev/null || return 1
  [[ -x "$output_dir/shelter-lite-macos.sh" ]] || return 1
  (cd "$output_dir" && shasum -a 256 -c shelter-lite-macos.sh.sha256) || return 1
  (cd "$output_dir" && shasum -a 256 -c shelter-lite-macos.zip.sha256) || return 1
  cp "$output_dir/shelter-lite-macos.zip" "$archived" || return 1
  # Exercise macOS's archive extraction and ensure Finder receives an executable.
  /usr/bin/ditto -x -k "$archived" "$extracted" || return 1
  [[ -x "$extracted/Shelter Lite.command" ]] || return 1
  cmp "$output_dir/shelter-lite-macos.sh" "$extracted/Shelter Lite.command" || return 1
  "$extracted/Shelter Lite.command" --help > "$SHELTER_CASE_DIR/command-help" || return 1
  assert_contains "$SHELTER_CASE_DIR/command-help" 'Shelter\ Lite.command' || return 1
  assert_absent "$SHELTER_CASE_DIR/command-help" 'Press Return' || return 1
  "$extracted/Shelter Lite.command" --unknown > "$SHELTER_CASE_DIR/command-error" 2>&1
  [[ $? == 2 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/command-error" 'Unknown option: --unknown' || return 1
  cp "$output_dir/shelter-lite-macos.sh" "$copied" || return 1
  /bin/bash "$copied" --help > "$SHELTER_CASE_DIR/help" || return 1
  assert_contains "$SHELTER_CASE_DIR/help" 'relocated\ setup.sh' || return 1
  assert_absent "$SHELTER_CASE_DIR/help" 'installers/macos/install.sh' || return 1
  assert_contains "$copied" 'Copyright (c) 2026 poby' || return 1
  assert_absent "$copied" 'source "$SHELTER_SCRIPT_DIR/' || return 1
  # Rebuilding unchanged sources must produce the same artifact and valid checksum.
  /bin/bash "$TEST_SOURCE_DIR/build.sh" --output-dir "$output_dir" > /dev/null || return 1
  cmp "$copied" "$output_dir/shelter-lite-macos.sh" || return 1
  cmp "$archived" "$output_dir/shelter-lite-macos.zip" || return 1
  /bin/bash "$TEST_SOURCE_DIR/build.sh" --output-dir > /dev/null 2>&1
  [[ $? == 2 ]] || return 1
  # Loading the single file must be silent and must not start installation.
  /bin/bash -c 'source "$1"' bash "$copied" > "$SHELTER_CASE_DIR/source-bundle" 2>&1 || return 1
  [[ ! -s "$SHELTER_CASE_DIR/source-bundle" ]] && assert_empty_log
}

run_test standalone_bundle_reproducible_and_relocatable test_standalone_build
run_test message_catalog_and_error_contract test_message_catalog
run_test preview_no_mutation test_preview
run_test check_missing test_check_missing
run_test full_unavailable test_full_unavailable
run_test no_tool_selection_and_invalid_options test_options
run_test unsupported_platforms_and_root test_platforms
run_test fixed_spec_install_and_idempotence test_fresh_and_repeat
run_test preserve_existing_node test_existing_node
run_test preserve_existing_ghostty_app_without_path test_existing_ghostty
run_test broken_ghostty_app_blocks_installation test_broken_ghostty
run_test ghostty_failure_stops_then_retry test_ghostty_failure_and_retry
run_test ghostty_install_requires_verification test_ghostty_verification_failure
run_test partial_node_blocked test_partial_node
run_test failure_stops_then_retry test_install_failure_and_retry
run_test download_failure_cleanup test_download_failure
run_test verify_installed_binary test_verification_failure
run_test preserve_unmanaged_config test_config_conflict
run_test broken_existing_binary test_broken_existing
run_test preserve_config_symlink test_config_symlink
run_test keep_python_install_only_uv test_python_existing_runtime
run_test distinguish_other_editor_code test_other_editor_code
run_test append_config_and_preserve_backup test_config_append_and_backup
run_test concise_success_keeps_details_in_private_log test_success_messages
run_test concise_failure_keeps_diagnostics_in_log test_failure_messages
run_test check_messages_show_only_observed_state test_check_messages
run_test preview_states_color_only_dot_and_result_title test_preview_cli
run_test install_cli_runs_isolated_workflow test_install_cli
run_test python_lookup_error_is_not_missing test_python_lookup_failure
run_test default_colors_and_explicit_overrides_keep_logs_plain test_forced_color_and_plain_log
run_test bare_color_forces_colors_without_consuming_next_option test_color_flag
run_test log_creation_failure_stops_install test_log_failure_stops_install
shelter_print test_summary "$TEST_PASSED" "$TEST_FAILED"
[[ $TEST_FAILED == 0 ]]
