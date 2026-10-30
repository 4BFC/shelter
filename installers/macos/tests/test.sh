#!/bin/bash
# Dependency-free Bash 3.2 tests. All installations and configuration writes use
# disposable fixtures; HOME and the user's actual package managers are untouched.

TEST_SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P) || exit 1
source "$TEST_SOURCE_DIR/install.sh" || exit 1
TEST_MODE=suite
TEST_SCENARIO=success
TEST_COLOR=auto
while [[ $# -gt 0 ]]; do
  case "$1" in
    --preview|--install|--intall)
      [[ "$TEST_MODE" == suite ]] || { printf '미리보기와 설치 흐름 테스트는 한 번에 하나만 실행하세요.\n' >&2; exit 2; }
      case "$1" in --preview) TEST_MODE=preview ;; *) TEST_MODE=install ;; esac
      if [[ $# -gt 1 && "$2" != --* ]]; then TEST_SCENARIO=$2; shift; fi
      case "$TEST_MODE:$TEST_SCENARIO" in
        preview:notification|preview:warning|preview:failure|preview:success|install:success|install:failure|install:dry-run) ;;
        *) printf '미리보기 상태: notification, warning, failure, success\n설치 테스트 상황: success, failure, dry-run\n' >&2; exit 2 ;;
      esac ;;
    --color)
      [[ $# -ge 2 ]] || { printf '%s\n' '--color 값이 필요합니다.' >&2; exit 2; }
      case "$2" in auto|always|never) TEST_COLOR=$2 ;; *) printf '지원하는 색상: auto, always, never\n' >&2; exit 2 ;; esac
      shift ;;
    --help|-h)
      cat <<'HELP'
사용법: /bin/bash installers/macos/tests/test.sh [옵션]

  옵션 없음                    자동 검증 전체 실행
  --preview [상태]              해당 메시지만 표시 (기본값: success)
    notification               안내, 청록색 ●
    warning                    주의할 상황과 다음 행동, 노란색 ●
    failure                    설치 실패와 오류 설명, 빨간색 ●와 결과 제목
    success                    설치 완료와 결과 설명, 초록색 ●와 결과 제목
  --install [상황]              임시 환경에서 설치기 전체 실행
    success                    처음부터 끝까지 설치 (기본값)
    failure                    uv 설치 실패와 중단 확인
    dry-run                    설치 예정 안내 확인
  --color auto|always|never     자동 색상 / 강제 색상 / 색상 끄기

--intall은 --install과 같습니다. 테스트는 실제 PC에 프로그램을 설치하지 않습니다.
HELP
      exit 0 ;;
    *) printf '알 수 없는 테스트 옵션: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
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
      [[ "$SHELTER_FAKE_SHOW_LOG" != 1 ]] || printf 'Homebrew 테스트 로그: %s\n' "$*"
      [[ "$SHELTER_FAKE_FAIL" != "${@: -1}" ]] || { printf 'Homebrew 테스트 오류: %s 설치 실패\n' "${@: -1}" >&2; exit 1; }
      case "$1" in
        node@24) make_tool node; make_tool npm ;;
        --cask) make_tool code ;;
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
      [[ "$SHELTER_FAKE_SHOW_LOG" != 1 ]] || printf 'uv 테스트 로그: Python %s 설치\n' "$3"
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
    printf '#!/bin/bash\nprintf "Homebrew 최초 설치 안내 (테스트)\\n"\n"$SHELTER_FAKE_DRIVER" create brew\n' > "$output"
  }
}

test_preview() {
  shelter_main --dry-run > "$SHELTER_CASE_DIR/output" || return 1
  assert_empty_log || return 1
  [[ ! -e "$SHELTER_CASE_DIR/config" ]] || return 1
  local tool
  for tool in Homebrew Git 'VS Code' 'Node.js + npm' 'Python + uv' 'GitHub CLI'; do
    assert_contains "$SHELTER_CASE_DIR/output" "$tool" || return 1
  done
  assert_contains "$SHELTER_CASE_DIR/output" '  미리보기' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '실제 설치와 설정 변경은 없습니다.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '새로 설치 예정' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '  미리보기 완료' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '실제 설치 0건, 설정 변경 0건' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '  설치 진행' && assert_absent "$SHELTER_CASE_DIR/output" '  설치 결과'
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
  assert_contains "$SHELTER_CASE_DIR/output" 'Homebrew 최초 설치 안내 (테스트)' || return 1
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

test_partial_node() {
  "$SHELTER_FAKE_DRIVER" create node
  PATH="$SHELTER_FAKE_PREFIX/opt/node@24/bin:$TEST_INITIAL_PATH"
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_LOG_FILE" '기존 환경 복구 필요' && assert_empty_log
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
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" 'GitHub CLI 설치 또는 결과 확인 실패' && assert_absent "$SHELTER_CASE_DIR/output" '전체 도구의 실행 확인이 끝났습니다'
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
  assert_contains "$SHELTER_LOG_FILE" 'Python + uv      | 부족한 구성 설치 완료' || return 1
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
  printf '메시지 미리보기: %s (실제 설치 없음)\n' "$1"
  case "$1" in
    failure) shelter_notice failure 'Python + uv 설치 또는 결과 확인 실패' ;;
    *) shelter_notice "$1" ;;
  esac
}

run_install_test() (
  local scenario=$1 status expected=0
  setup_fixture "install-$scenario" || return 1
  export SHELTER_FAKE_SHOW_LOG=1
  printf '설치 흐름 테스트: 임시 환경에서 실행합니다. 실제 PC 설치는 없으며 임시 파일은 자동 정리됩니다.\n'
  case "$scenario" in
    dry-run) shelter_main --dry-run --color "$TEST_COLOR"; status=$? ;;
    success) shelter_main --color "$TEST_COLOR"; status=$? ;;
    failure)
      export SHELTER_FAKE_FAIL=uv
      expected=1
      shelter_main --color "$TEST_COLOR"; status=$? ;;
  esac
  if [[ "$status" != "$expected" ]]; then
    printf '테스트 오류: 예상 종료 코드 %s, 실제 %s\n' "$expected" "$status" >&2
    return 1
  fi
)

test_success_messages() {
  seed_preview_tools || return 1
  export SHELTER_FAKE_SHOW_LOG=1
  shelter_main > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '  설치 완료' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '------------------------------------------------------------' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● success: 개발 도구가 준비되었습니다.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● warning: 새 실행 경로는 현재 터미널에 아직 반영되지 않았습니다.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '터미널과 편집기를 다시 열어' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '  설치 전' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '  설치 결과' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '테스트 로그' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" 'fixture-version' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Node.js + npm    | 기존 설치 유지 | v24.22.2 / 11.0.0 → v24.22.2 / 11.0.0' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'VS Code          | 신규 설치 완료 | 없음 → code fixture-version' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Homebrew 테스트 로그:' || return 1
  [[ $(wc -l < "$SHELTER_CASE_DIR/output") -le 8 ]] && [[ $(LC_ALL=C ls -ld "$SHELTER_LOG_FILE") == -rw-------* ]]
}

test_failure_messages() {
  seed_preview_tools || return 1
  export SHELTER_FAKE_FAIL=uv
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '  설치 실패' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● error: Python + uv 설치 또는 결과 확인 실패' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● warning: 이미 진행된 설치와 설정 변경은 자동으로 되돌리지 않습니다.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '● note: 상세 로그에서 원인을 확인하고 해결한 뒤 다시 실행하세요.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" "상세 로그: $SHELTER_LOG_FILE" || return 1
  assert_contains "$SHELTER_LOG_FILE" 'VS Code          | 신규 설치 완료' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Python + uv      | 실패' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'GitHub CLI       | 미실행' || return 1
  assert_contains "$SHELTER_LOG_FILE" 'Homebrew 테스트 오류: uv 설치 실패' || return 1
  assert_contains "$SHELTER_LOG_FILE" '● error: Python + uv 설치 또는 결과 확인 실패' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '  설치 완료' && ! grep -Fqx -- '  셸 설정' "$SHELTER_CASE_DIR/output"
}

test_check_messages() {
  seed_preview_tools || return 1
  shelter_main --check --color always > "$SHELTER_CASE_DIR/output"
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '  상태 확인' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" '  현재 상태' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" "$SHELTER_FAKE_PREFIX/bin/git" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;33m  확인 필요\033[0m' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m●\033[0m  Homebrew' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" $'\033[1;36m' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '예정' && assert_absent "$SHELTER_CASE_DIR/output" '  설치 결과' && assert_empty_log
}

test_preview_cli() {
  local scenario expected
  for scenario in notification warning failure success; do
    case "$scenario" in
      notification) expected=$'\033[1;36m●\033[0m note: Shelter Lite 초기 설정을 시작합니다.' ;;
      warning) expected=$'\033[1;33m●\033[0m warning: 새 실행 경로는 현재 터미널에 아직 반영되지 않았습니다. 터미널과 편집기를 다시 열어 사용하세요.' ;;
      failure) expected=$'\033[1;31m●\033[0m error: Python + uv 설치 또는 결과 확인 실패' ;;
      success) expected=$'\033[1;32m●\033[0m success: 개발 도구가 준비되었습니다.' ;;
    esac
    NO_COLOR=1 /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview "$scenario" --color always > "$SHELTER_CASE_DIR/$scenario" 2>&1 || return 1
    assert_contains "$SHELTER_CASE_DIR/$scenario" "메시지 미리보기: $scenario (실제 설치 없음)" || return 1
    # Only the dot is colored; the prefix and body remain in the terminal's default color.
    grep -Fxq -- "$expected" "$SHELTER_CASE_DIR/$scenario" || return 1
    case "$scenario" in
      failure) assert_contains "$SHELTER_CASE_DIR/$scenario" $'\033[1;31m  설치 실패\033[0m' || return 1 ;;
      success) assert_contains "$SHELTER_CASE_DIR/$scenario" $'\033[1;32m  설치 완료\033[0m' || return 1 ;;
    esac
    assert_absent "$SHELTER_CASE_DIR/$scenario" 'fixture-version' || return 1
    /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview "$scenario" --color never > "$SHELTER_CASE_DIR/$scenario-plain" 2>&1 || return 1
    assert_absent "$SHELTER_CASE_DIR/$scenario-plain" $'\033' || return 1
    assert_contains "$SHELTER_CASE_DIR/$scenario-plain" '● ' || return 1
  done
  NO_COLOR=1 /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --preview > "$SHELTER_CASE_DIR/default-preview" || return 1
  assert_contains "$SHELTER_CASE_DIR/default-preview" '● success: 개발 도구가 준비되었습니다.' || return 1
  assert_absent "$SHELTER_CASE_DIR/default-preview" $'\033' || return 1
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
    assert_contains "$SHELTER_CASE_DIR/$scenario" '설치 흐름 테스트: 임시 환경에서 실행합니다.' || return 1
    assert_absent "$SHELTER_CASE_DIR/$scenario" '테스트 오류:' || return 1
    case "$scenario" in
      success) assert_contains "$SHELTER_CASE_DIR/$scenario" '● success: 개발 도구가 준비되었습니다.' || return 1 ;;
      failure) assert_contains "$SHELTER_CASE_DIR/$scenario" '● error: Python + uv 설치 또는 결과 확인 실패' || return 1 ;;
      dry-run) assert_contains "$SHELTER_CASE_DIR/$scenario" '실제 설치 0건, 설정 변경 0건' || return 1 ;;
    esac
  done
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --intall --color never > "$SHELTER_CASE_DIR/alias" 2>&1 || return 1
  assert_contains "$SHELTER_CASE_DIR/alias" '● success: 개발 도구가 준비되었습니다.' || return 1
  [[ -z $(ls -A "$TMPDIR") ]] || return 1
  /bin/bash "$TEST_SOURCE_DIR/tests/test.sh" --install unknown > /dev/null 2>&1
  [[ $? == 2 ]] && assert_empty_log
}

test_forced_color_and_plain_log() {
  seed_preview_tools || return 1
  NO_COLOR=1 shelter_main --color always > "$SHELTER_CASE_DIR/output" || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m  설치 완료\033[0m' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;33m●\033[0m warning:' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;36m●\033[0m note: Shelter Lite 초기 설정을 시작합니다.' || return 1
  assert_contains "$SHELTER_CASE_DIR/output" $'\033[1;32m●\033[0m success: 개발 도구가 준비되었습니다.' || return 1
  assert_absent "$SHELTER_LOG_FILE" $'\033' || return 1
  shelter_main --color never > "$SHELTER_CASE_DIR/plain" || return 1
  assert_absent "$SHELTER_CASE_DIR/plain" $'\033' || return 1
  assert_absent "$SHELTER_CASE_DIR/plain" 'warning:' || return 1
  shelter_main --color always --unknown > "$SHELTER_CASE_DIR/invalid-stdout" 2> "$SHELTER_CASE_DIR/invalid-stderr"
  [[ $? == 2 ]] && [[ ! -s "$SHELTER_CASE_DIR/invalid-stdout" ]] && \
    assert_contains "$SHELTER_CASE_DIR/invalid-stderr" $'\033[1;31m●\033[0m error: 알 수 없는 옵션: --unknown'
}

test_log_failure_stops_install() {
  shelter_create_log() { return 1; }
  shelter_main > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] && assert_contains "$SHELTER_CASE_DIR/output" '  설치 실패' && assert_absent "$SHELTER_CASE_DIR/output" 'warning:' && assert_empty_log
}

test_python_lookup_failure() {
  "$SHELTER_FAKE_DRIVER" create brew
  "$SHELTER_FAKE_DRIVER" create uv
  export SHELTER_FAKE_PYTHON_LOOKUP_ERROR=1
  shelter_main --dry-run > "$SHELTER_CASE_DIR/output" 2>&1
  [[ $? == 1 ]] || return 1
  assert_contains "$SHELTER_CASE_DIR/output" 'Python 조회 실패' || return 1
  assert_absent "$SHELTER_CASE_DIR/output" '  미리보기 완료' && assert_empty_log
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
run_test concise_success_keeps_details_in_private_log test_success_messages
run_test concise_failure_keeps_diagnostics_in_log test_failure_messages
run_test check_messages_show_only_observed_state test_check_messages
run_test preview_states_color_only_dot_and_result_title test_preview_cli
run_test install_cli_runs_isolated_workflow test_install_cli
run_test python_lookup_error_is_not_missing test_python_lookup_failure
run_test explicit_color_overrides_no_color_and_logs_stay_plain test_forced_color_and_plain_log
run_test log_creation_failure_stops_install test_log_failure_stops_install
printf '\n%s passed, %s failed\n' "$TEST_PASSED" "$TEST_FAILED"
[[ $TEST_FAILED == 0 ]]
