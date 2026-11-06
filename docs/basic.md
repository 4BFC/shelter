# Codex와 Claude Code 설치

터미널에서 AI와 대화할 수 있는 **Codex CLI**와 **Claude Code** 설치 방법입니다. 아래 공식 설치 명령은 Homebrew, WinGet, Node.js 사전 설치 없이 사용할 수 있습니다.

## 1. 설치

사용하는 운영체제의 명령만 **한 줄씩 복사하고 Enter**를 누르세요.

### macOS

`Command + Space`를 누르고 **터미널**을 검색해 실행합니다.

Codex:

```sh
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Claude Code:

```sh
curl -fsSL https://claude.ai/install.sh | bash
```

### Windows

시작 메뉴에서 **Windows PowerShell**을 검색해 실행합니다. 명령 프롬프트(CMD) 대신 PowerShell에서 실행하세요.

Codex:

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

Claude Code:

```powershell
irm https://claude.ai/install.ps1 | iex
```

## 2. 설치 확인과 실행

설치가 끝나면 **터미널 또는 PowerShell 창을 닫고 새로 연 뒤**, 아래 명령을 하나씩 입력합니다.

| 도구 | 설치 확인: 버전 번호가 나오면 성공 | 대화 시작 |
| --- | --- | --- |
| Codex | `codex --version` | `codex` |
| Claude Code | `claude --version` | `claude` |

처음 실행하면 화면 안내에 따라 브라우저에서 로그인합니다. Codex는 **Sign in with ChatGPT**, Claude Code는 **Claude 계정 로그인**을 선택하면 됩니다. Claude Code는 이용 가능한 구독 또는 API 계정이 필요하며, 설치와 서비스 이용 요금은 별개입니다.

명령을 찾을 수 없다는 메시지가 나오면 설치 완료 화면의 **PATH 안내**를 확인하세요. PATH는 설치한 프로그램을 터미널에서 찾기 위한 경로 설정입니다.

공식 안내: [Codex CLI](https://learn.chatgpt.com/docs/codex/cli), [Claude Code 설치](https://code.claude.com/docs/en/quickstart), [Claude Code 계정과 설치 문제](https://code.claude.com/docs/en/setup).

확인일: 2026-11-06. 이 문서는 수동 설치 안내이며, 현재 Shelter Lite의 자동 설치 항목에 두 도구를 추가하지는 않습니다.
