#!/bin/bash
# macOS ships Bash 3.2. Keep this entry point compatible with it.

SHELTER_SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
# shellcheck source=tools.sh
source "$SHELTER_SCRIPT_DIR/tools.sh" || exit 1

shelter_help() {
  cat <<'HELP'
Shelter Lite — 나의 환경을 지키는 피난처

사용법: /bin/bash installers/macos/install.sh [옵션]

  --check         설치 상태만 확인. 미설치/오류가 있으면 종료 코드 1
  --dry-run       설치 계획만 표시. 다운로드와 설정 변경 없음
  --mode lite     라이트 버전 (기본값). full은 아직 제공하지 않음
  --color MODE    색상: auto(기본값), always(강제 표시), never(끄기)
  -h, --help      도움말

옵션 없이 실행하면 고정 스펙 전체를 순서대로 준비합니다. 도구 선택 메뉴는 없습니다.
Homebrew → Git → VS Code → Node.js/npm → Python/uv → GitHub CLI
지원 범위: macOS 15 이상, Apple Silicon, zsh/bash. sudo로 실행하지 마세요.
정상 실행되는 기존 도구는 설치를 건너뜁니다. 새 패키지의 의존성은 Homebrew가 처리합니다.
새 Node는 24 계열, 새 Python은 uv로 3.14 계열을 설치합니다.
기본 화면에는 최종 결과와 짧은 안내를 표시하며, 필요한 경우에만 경고를 덧붙입니다.
상세 내용은 설정 디렉터리의 logs/에 저장합니다.
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
  shelter_section '설치 결과'
  printf '  도구 | 처리 결과 | 설치 전 → 확인 결과\n\n'
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    case "${SHELTER_RESULTS[$i]}" in
      실패) tone=error ;;
      미실행) tone=warning ;;
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
    shelter_section '현재 상태'
    printf '  도구 | 상태 | 확인한 버전과 실행 경로\n\n'
  else
    shelter_section '설치 전'
    printf '  도구 | 현재 상태 | 예정 작업\n\n'
  fi
  for tool in "${SHELTER_TOOLS[@]}"; do
    shelter_probe "$tool"
    SHELTER_BEFORE+=("$SHELTER_VERSION")
    SHELTER_RESULTS+=('미실행')
    SHELTER_AFTER+=('실행 후 확인 없음')
    case "$SHELTER_STATE" in
      ready) status='설치됨'; action='기존 설치 유지 예정'; tone=success ;;
      blocked) status='확인 필요'; action='기존 환경 복구 필요'; tone=error; blocked=1 ;;
      partial) status='일부 설치됨'; action='부족한 구성 설치 예정'; tone=warning; missing=1 ;;
      *) status='설치 안 됨'; action='새로 설치 예정'; tone=warning; missing=1 ;;
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
      shelter_section '확인 완료' success
      printf '전체 도구를 실행할 수 있습니다. 설치와 설정 변경은 없습니다.\n'
      return 0
    fi
    shelter_section '확인 필요' warning
    printf '미설치 또는 실행 오류가 있습니다. 설치와 설정 변경은 없습니다.\n'
    return 1
  fi
  if [[ $missing == 1 ]]; then
    shelter_probe brew
    if [[ "$SHELTER_STATE" == blocked ]]; then
      blocked=1
      shelter_error "Homebrew 확인 필요: $SHELTER_DETAIL"
    elif [[ "$SHELTER_STATE" != ready ]]; then
      shelter_message warning '실제 설치 시 Homebrew 공식 설치기를 실행합니다. 관리자 인증과 개발 도구 설치가 필요할 수 있습니다.'
    fi
    shelter_section '설치 예정 내역'
    printf '없는 구성 요소만 준비합니다.\n'
    for tool in "${SHELTER_TOOLS[@]}"; do
      shelter_probe "$tool"
      [[ "$SHELTER_STATE" == ready || "$SHELTER_STATE" == blocked ]] || shelter_describe_install "$tool"
    done
  else
    printf '\n새로 설치할 도구가 없습니다.\n'
  fi
  if [[ ${#SHELTER_PATHS[@]} -gt 0 || $missing == 1 ]]; then
    shelter_section '설정 예정'
    printf '필요한 실행 경로를 저장하고 셸 설정에 연결합니다. 변경할 기존 파일은 백업합니다.\n'
    printf '  환경 파일: %s\n' "$SHELTER_ENV_FILE"
    printf '  셸 설정: %s\n' "${SHELTER_RC_FILES[@]}"
  fi
  [[ $blocked == 0 ]] || { shelter_error '실행 오류 또는 일부만 설치된 Node/npm이 있습니다. 기존 설치를 먼저 복구하세요.'; return 1; }
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
        [[ $# -ge 2 && "$2" != --* ]] || { shelter_error "$option 값이 필요합니다."; return 2; }
        mode=$2
        shift ;;
      --color)
        [[ $# -ge 2 ]] || { shelter_error '--color 값이 필요합니다.'; return 2; }
        case "$2" in auto|always|never) SHELTER_COLOR=$2 ;; *) shelter_error '--color는 auto, always, never 중 하나입니다.'; return 2 ;; esac
        shift ;;
      --check|--dry-run)
        [[ "$SHELTER_ACTION" == install ]] || { shelter_error '--check와 --dry-run은 함께 사용할 수 없습니다.'; return 2; }
        SHELTER_ACTION=${option#--} ;;
      *) shelter_error "알 수 없는 옵션: $option"; return 2 ;;
    esac
    shift
  done
  case "$mode" in
    lite) ;;
    full) shelter_error '정식 버전은 아직 준비 중입니다. 라이트 버전을 사용하세요.'; return 2 ;;
    *) shelter_error '지원하는 모드는 lite입니다.'; return 2 ;;
  esac
  shelter_check_platform || return
  shelter_shell_targets || return
  if [[ "$SHELTER_ACTION" != install ]]; then
    shelter_run
    return $?
  fi
  if ! SHELTER_LOG_FILE=$(shelter_create_log); then
    shelter_notice failure '설치 로그를 만들 수 없습니다.'
    shelter_message info '설정 디렉터리의 접근 권한을 확인한 뒤 다시 실행하세요.'
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
    shelter_notice failure "${SHELTER_FAILURE_MESSAGE:-설치를 완료하지 못했습니다.}"
    if [[ $SHELTER_INSTALL_ATTEMPTED == 1 || $SHELTER_SETTINGS_ATTEMPTED == 1 ]]; then
      shelter_message warning '이미 진행된 설치와 설정 변경은 자동으로 되돌리지 않습니다.'
    fi
    shelter_message info '상세 로그에서 원인을 확인하고 해결한 뒤 다시 실행하세요.'
    shelter_message info "상세 로그: $SHELTER_LOG_FILE"
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
      shelter_section '미리보기'
      printf '실제 설치와 설정 변경은 없습니다.\n' ;;
    check)
      shelter_section '상태 확인'
      printf '현재 설치 상태만 확인합니다.\n' ;;
    install)
      shelter_section '설치 모드'
      printf '고정 스펙 전체의 초기 설정을 시작합니다.\n' ;;
  esac
  shelter_plan || return
  if [[ "$SHELTER_ACTION" == dry-run ]]; then
    shelter_section '미리보기 완료' success
    printf '실제 설치 0건, 설정 변경 0건입니다.\n'
    return 0
  fi
  [[ "$SHELTER_ACTION" == install ]] || return 0
  shelter_section '설치 진행'
  for ((i=0; i<${#SHELTER_TOOLS[@]}; i++)); do
    tool=${SHELTER_TOOLS[$i]}
    name=$(shelter_tool_name "$tool")
    shelter_probe "$tool"
    if [[ "$SHELTER_STATE" == ready ]]; then
      SHELTER_RESULTS[$i]='기존 설치 유지'
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_message success "기존 설치 유지: $name — $SHELTER_VERSION"
      continue
    fi
    if [[ "$SHELTER_STATE" == blocked ]]; then
      SHELTER_RESULTS[$i]='실패'
      SHELTER_AFTER[$i]=$SHELTER_VERSION
      shelter_results
      shelter_error "$name 상태가 변경됐습니다: $SHELTER_DETAIL"
      return 1
    fi
    result='신규 설치 완료'
    [[ "$SHELTER_STATE" != partial ]] || result='부족한 구성 설치 완료'
    shelter_message info "$name 설치 중"
    printf '%s\n' "--- 설치 도구 로그 시작: $name ---"
    status=0
    SHELTER_INSTALL_ATTEMPTED=1
    shelter_ensure_brew && shelter_install_tool "$tool" && shelter_refresh_paths || status=1
    printf '%s\n' "--- 설치 도구 로그 끝: $name ---"
    shelter_probe "$tool"
    SHELTER_AFTER[$i]=$SHELTER_VERSION
    if [[ $status != 0 || "$SHELTER_STATE" != ready ]]; then
      SHELTER_RESULTS[$i]='실패'
      shelter_results
      printf '확인 정보: %s\n' "$SHELTER_DETAIL"
      shelter_error "$name 설치 또는 결과 확인 실패"
      printf '완료된 설치와 일부 설치된 구성 요소는 남습니다. 오류를 해결한 뒤 같은 명령으로 다시 시도하세요.\n' >&2
      return 1
    fi
    SHELTER_RESULTS[$i]=$result
    shelter_message success "$name 설치 완료 — $SHELTER_VERSION"
  done
  shelter_results
  shelter_section '셸 설정'
  [[ ${#SHELTER_PATHS[@]} == 0 ]] || SHELTER_SETTINGS_ATTEMPTED=1
  shelter_save_paths || { shelter_error '도구는 설치됐지만 셸 설정 반영에 실패했습니다.'; return 1; }
  if [[ ${#SHELTER_PATHS[@]} -gt 0 ]]; then
    shelter_message warning '경로 설정을 저장했습니다. 현재 터미널에는 아직 반영되지 않았습니다.'
    printf '현재 터미널에 경로를 반영하려면 실행하세요:\n  source %q\n' "$SHELTER_ENV_FILE"
    printf '새 터미널에서도 확인하세요. 실행 중인 프로그램은 재시작해야 새 환경을 사용합니다.\n'
  else
    shelter_message success '추가할 실행 경로가 없습니다.'
  fi
  shelter_section '설치 완료' success
  printf '라이트 전체 도구의 실행 확인이 끝났습니다.\n'
  printf '버전과 실행 경로는 --check로 확인할 수 있습니다. 보안 취약점이나 최신 버전 판정은 포함하지 않습니다.\n'
  printf 'Git 사용자 정보와 GitHub 로그인은 별도로 설정합니다.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'printf "\n중단했습니다. 이미 완료된 설치는 유지됩니다.\n" >&2; exit 130' INT
  shelter_main "$@"
  exit $?
fi
