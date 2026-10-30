#!/bin/bash
# Dependency-free Bash 3.2 tests. All installations and configuration writes use
# disposable fixtures; HOME and the user's actual package managers are untouched.

TEST_SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P) || exit 1
source "$TEST_SOURCE_DIR/install.sh"
SHELTER_TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/shelter-tests.XXXXXX") || exit 1
trap 'rm -rf "$SHELTER_TEST_ROOT"' EXIT
TEST_PASSED=0
TEST_FAILED=0

assert_contains() { grep -Fq -- "$2" "$1" || { printf 'Missing: %s\n' "$2"; return 1; }; }
assert_absent() { ! grep -Fq -- "$2" "$1" || { printf 'Unexpected: %s\n' "$2"; return 1; }; }
assert_empty_log() { [[ ! -s "$SHELTER_FAKE_LOG" ]]; }

setup_fixture() {
  SHELTER_CASE_DIR="$SHELTER_TEST_ROOT/$1 with spaces"
  export SHELTER_FAKE_PREFIX="$SHELTER_CASE_DIR/brew"
  export SHELTER_FAKE_PY_BIN="$SHELTER_CASE_DIR/python-bin"
  export SHELTER_FAKE_DRIVER="$SHELTER_CASE_DIR/driver"
  export SHELTER_FAKE_LOG="$SHELTER_CASE_DIR/actions.log"
  export SHELTER_FAKE_FAIL='' SHELTER_FAKE_BROKEN='' SHELTER_FAKE_NODE_VERSION=v24.22.2
  export TMPDIR="$SHELTER_CASE_DIR/tmp"
  mkdir -p "$SHELTER_CASE_DIR/bin" "$TMPDIR" || return 1
  : > "$SHELTER_FAKE_LOG"
  TEST_INITIAL_PATH="$SHELTER_CASE_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  export PATH="$TEST_INITIAL_PATH"
  hash -r
  cat > "$SHELTER_FAKE_DRIVER" <<'FAKE'
#!/bin/bash
make_tool() {
  local name=$1 target="$SHELTER_FAKE_PREFIX/bin/$1"
  case "$name" in
    node|npm) target="$SHELTER_FAKE_PREFIX/opt/node@24/bin/$name" ;;
    python3.14) target="$SHELTER_FAKE_PY_BIN/$name" ;;
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
      [[ "$SHELTER_FAKE_FAIL" != "${@: -1}" ]] || exit 1
      case "$1" in
        node@24) make_tool node; make_tool npm ;;
        --cask) make_tool code ;;
        *) make_tool "$1" ;;
      esac ;;
    *) exit 90 ;;
  esac
elif [[ "$name" == uv ]]; then
  [[ "$1" != --no-config ]] || shift
  case "$1 $2" in
    'python dir') printf '%s\n' "$SHELTER_FAKE_PY_BIN" ;;
    'python find')
      [[ -x "$SHELTER_FAKE_PY_BIN/python3.14" ]] || exit 1
      printf '%s\n' "$SHELTER_FAKE_PY_BIN/python3.14" ;;
    'python install')
      printf 'uv python install %s\n' "$3" >> "$SHELTER_FAKE_LOG"
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
    printf '#!/bin/bash\n"$SHELTER_FAKE_DRIVER" create brew\n' > "$output"
  }
}

test_preview() {
  shelter_main --dry-run > "$SHELTER_CASE_DIR/output" || return 1
  assert_empty_log || return 1
  [[ ! -e "$SHELTER_CASE_DIR/config" ]] || return 1
  local tool
  for tool in brew git vscode node python gh; do
    assert_contains "$SHELTER_CASE_DIR/output" "$tool" || return 1
  done
}

test_check_missing() {
  shelter_main --check > "$SHELTER_CASE_DIR/output"
  [[ $? == 1 ]] && assert_empty_log && [[ ! -e "$SHELTER_CASE_DIR/config" ]]
}

test_full_unavailable() {
  shelter_main --mode full > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 2 ]] && assert_contains "$SHELTER_CASE_DIR/output" '정식 버전은 아직' && assert_empty_log
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
brew install node@24
brew install uv
uv python install 3.14
brew install gh
EXPECTED
  diff -u "$SHELTER_CASE_DIR/expected" "$SHELTER_FAKE_LOG" || return 1
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
  assert_contains "$SHELTER_CASE_DIR/output" 'v22.0.0' && assert_absent "$SHELTER_FAKE_LOG" 'install node@24'
}

test_partial_node() {
  "$SHELTER_FAKE_DRIVER" create node
  PATH="$SHELTER_FAKE_PREFIX/opt/node@24/bin:$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" 'blocked' && assert_empty_log
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
  [[ ! -e "$SHELTER_FAKE_PREFIX/bin/brew" && ! -e "$SHELTER_CASE_DIR/config" ]] || return 1
  [[ -z $(ls -A "$TMPDIR") ]]
}

test_verification_failure() {
  export SHELTER_FAKE_BROKEN=gh
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" 'gh 결과 확인 실패' && assert_absent "$SHELTER_CASE_DIR/output" '전체 도구의 실행 확인이 끝났습니다'
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
  [[ $? == 1 ]] && assert_empty_log
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

run_test() {
  local name=$1 function=$2 output="$SHELTER_TEST_ROOT/$1.log"
  if (setup_fixture "$name" && "$function") > "$output" 2>&1; then
    printf 'PASS %s\n' "$name"
    TEST_PASSED=$((TEST_PASSED + 1))
  else
    printf 'FAIL %s\n' "$name"
    cat "$output"
    TEST_FAILED=$((TEST_FAILED + 1))
  fi
}

run_test preview_no_mutation test_preview
run_test check_missing test_check_missing
run_test full_unavailable test_full_unavailable
run_test no_tool_selection_and_invalid_options test_options
run_test unsupported_platforms_and_root test_platforms
run_test fixed_spec_install_and_idempotence test_fresh_and_repeat
run_test preserve_existing_node test_existing_node
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
printf '\n%s passed, %s failed\n' "$TEST_PASSED" "$TEST_FAILED"
[[ $TEST_FAILED == 0 ]]
