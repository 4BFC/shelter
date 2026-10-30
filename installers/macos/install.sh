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
  -h, --help      도움말

옵션 없이 실행하면 고정 스펙 전체를 순서대로 준비합니다. 도구 선택 메뉴는 없습니다.
Homebrew → Git → VS Code → Node.js/npm → Python/uv → GitHub CLI
지원 범위: macOS 15 이상, Apple Silicon, zsh/bash. sudo로 실행하지 마세요.
정상 실행되는 기존 도구는 설치를 건너뜁니다. 새 패키지의 의존성은 Homebrew가 처리합니다.
새 Node는 24 계열, 새 Python은 uv로 3.14 계열을 설치합니다.
HELP
}

shelter_plan() {
  local tool missing=0 blocked=0
  printf '\n라이트 고정 스펙과 현재 상태\n'
  for tool in "${SHELTER_TOOLS[@]}"; do
    shelter_probe "$tool"
    printf '  %-8s [%s] %s\n' "$tool" "$SHELTER_STATE" "$SHELTER_DETAIL"
    case "$SHELTER_STATE" in
      ready) ;;
      blocked) blocked=1 ;;
      *) missing=1 ;;
    esac
  done
  if [[ "$SHELTER_ACTION" == check ]]; then
    [[ $missing == 0 && $blocked == 0 ]]
    return
  fi
  if [[ $missing == 1 ]]; then
    shelter_probe brew
    if [[ "$SHELTER_STATE" == blocked ]]; then
      blocked=1
      shelter_error "Homebrew 확인 필요: $SHELTER_DETAIL"
    elif [[ "$SHELTER_STATE" != ready ]]; then
      printf '\nHomebrew 공식 설치기를 내려받아 실행합니다. 관리자 인증과 개발 도구 설치가 필요할 수 있습니다.\n'
    fi
    printf '\n설치 계획: 없는 도구만 준비합니다. 기존 도구의 버전은 유지합니다.\n'
    for tool in "${SHELTER_TOOLS[@]}"; do
      shelter_probe "$tool"
      [[ "$SHELTER_STATE" == ready || "$SHELTER_STATE" == blocked ]] || shelter_describe_install "$tool"
    done
  else
    printf '\n새로 설치할 도구가 없습니다.\n'
  fi
  if [[ ${#SHELTER_PATHS[@]} -gt 0 || $missing == 1 ]]; then
    printf '필요한 실행 경로를 Shelter 설정 파일에 저장하고 셸 설정에 연결합니다. 변경할 기존 파일은 백업합니다.\n'
    printf '  환경 파일: %s\n' "$SHELTER_ENV_FILE"
    printf '  셸 설정: %s\n' "${SHELTER_RC_FILES[@]}"
  fi
  [[ $blocked == 0 ]] || { shelter_error '실행 오류 또는 일부만 설치된 Node/npm이 있습니다. 기존 설치를 먼저 복구하세요.'; return 1; }
}

shelter_main() {
  set -o pipefail
  local mode=lite option tool
  SHELTER_ACTION=install
  SHELTER_TOOLS=(brew git vscode node python gh)
  SHELTER_PATHS=()
  SHELTER_RC_FILES=()
  SHELTER_BREW=''
  SHELTER_PREFIX=''
  while [[ $# -gt 0 ]]; do
    option=$1
    case "$option" in
      -h|--help) shelter_help; return 0 ;;
      --mode)
        [[ $# -ge 2 && "$2" != --* ]] || { shelter_error "$option 값이 필요합니다."; return 2; }
        mode=$2
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
  shelter_refresh_paths || return
  printf 'Shelter Lite — macOS %s / %s\n' "$SHELTER_OS_VERSION" "$SHELTER_ARCH"
  printf 'ready=실행 가능, missing=설치 필요, partial=일부 설치 필요, blocked=기존 환경 확인 필요\n'
  shelter_plan || return
  [[ "$SHELTER_ACTION" == install ]] || return 0
  for tool in "${SHELTER_TOOLS[@]}"; do
    shelter_probe "$tool"
    if [[ "$SHELTER_STATE" == ready ]]; then
      printf '[유지] %s — %s\n' "$tool" "$SHELTER_DETAIL"
      continue
    fi
    [[ "$SHELTER_STATE" != blocked ]] || { shelter_error "$tool 상태가 변경됐습니다: $SHELTER_DETAIL"; return 1; }
    shelter_ensure_brew || { shelter_error 'Homebrew 준비에 실패했습니다. 앞서 설치된 도구는 유지됩니다.'; return 1; }
    shelter_install_tool "$tool" || { shelter_error "$tool 설치 실패. 앞서 설치된 도구는 유지됩니다. 같은 명령으로 다시 시도할 수 있습니다."; return 1; }
    shelter_refresh_paths || return
    shelter_probe "$tool"
    [[ "$SHELTER_STATE" == ready ]] || { shelter_error "$tool 결과 확인 실패: $SHELTER_DETAIL"; return 1; }
    printf '[완료] %s — %s\n' "$tool" "$SHELTER_DETAIL"
  done
  shelter_save_paths || { shelter_error '도구는 설치됐지만 셸 설정 반영에 실패했습니다.'; return 1; }
  printf '\n라이트 전체 도구의 실행 확인이 끝났습니다. 보안 취약점이나 최신 버전 여부를 판정한 결과는 아닙니다.\n'
  if [[ ${#SHELTER_PATHS[@]} -gt 0 ]]; then
    printf '현재 터미널에 경로를 반영하려면 실행하세요:\n  source %q\n' "$SHELTER_ENV_FILE"
    printf '새 터미널에서도 확인하세요. 실행 중인 프로그램은 재시작해야 새 환경을 사용합니다.\n'
  fi
  printf 'Git 사용자 정보와 GitHub 로그인은 별도로 설정합니다.\n'
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  trap 'printf "\n중단했습니다. 이미 완료된 설치는 유지됩니다.\n" >&2; exit 130' INT
  shelter_main "$@"
  exit $?
fi
