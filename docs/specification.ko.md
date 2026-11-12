# Shelter 기술 사양

[English](./specification.md) · [한국어](./specification.ko.md) · [日本語](./specification.jp.md)

[README](../language/ko/README.md)

## 제품 구성

**웹사이트**는 보안 정보와 대응 방법을 제공하는 사용자 접점입니다.
**정보 수집 기능**은 공식 보안 공지와 릴리스 정보를 추적하는 기반입니다.
**CLI**는 그 정보를 사용자 PC의 상태와 연결하는 도구입니다.

| 구성           | 계획한 역할                                     | 사용자에게 제공할 정보                       |
| -------------- | ----------------------------------------------- | -------------------------------------------- |
| 웹사이트       | 보안 이슈와 업데이트 정보를 모아 쉽게 설명      | 문제의 내용, 영향받는 버전, 대응 방법과 출처 |
| 정보 수집 기능 | 보안 공지와 업데이트 변경 사항 추적             | 원문 링크, 게시 시점, 마지막 확인 시점       |
| CLI            | 설치 상태 확인, 관련 알림, 업데이트와 결과 검증 | 현재 상태, 필요한 변경, 적용 결과            |

보안 이슈를 빠르게 파악할 수 있도록 지속적인 추적을 목표로 합니다. 수집 주기와 알림 지연은 아직 정하지 않았습니다.
Codex, Claude Code 같은 도구의 통합 설치와 관리는 이후 확장 대상으로 검토합니다.

**Shelter Lite**는 정해진 스펙 전체를 Shell 설치기로 준비하고 결과를 확인하는 초기 설정입니다. 개별 도구를 선택하거나 제외하는 기능은 제공하지 않습니다.
**정식 버전**은 설치 후에도 상태 확인, 보안 알림과 업데이트를 지속적으로 제공할 CLI입니다.
설치 스크립트는 운영체제별 `installers/macos/`와 `installers/windows/`에서 관리합니다. 정식 CLI는 별도 Python 패키지인 `src/shelter/`에 있으며, 개발 환경과 의존성은 uv로 관리합니다. 패키지 설정과 도움말, 버전만 출력하는 `shelter` 진입점은 구현했고, 도구 탐색, 업데이트 조회와 Lite 호출은 아직 구현하지 않았습니다. [CLI 탐색과 업데이트 조회 계획](plans/shelter-cli.md)을 참고하세요.

## 라이트 고정 설치 스펙

아래 항목은 모두 라이트에 포함됩니다. Homebrew는 설치 관리자, Git은 버전 관리 도구, VS Code는 편집기, Ghostty는 명령을 입력하고 실행하는 터미널 앱입니다. Node.js와 Python은 실행 환경이며 npm과 uv는 해당 환경의 관리 도구입니다. GitHub CLI는 GitHub 연동 도구입니다.

| 순서 | 설치 대상 | 역할 | 새로 설치할 때의 정책 |
| --- | --- | --- | --- |
| 1 | [Homebrew](https://docs.brew.sh/Installation) | 프로그램 설치 기반 | 공식 설치기로 준비 |
| 2 | [Git](https://formulae.brew.sh/formula/git) | 파일 변경 이력 관리 | Homebrew의 `git`, 정상 실행되는 Apple Git도 유지 |
| 3 | [VS Code](https://formulae.brew.sh/cask/visual-studio-code) | 파일과 코드 편집 | Homebrew의 `visual-studio-code`, 기존 `code` 명령 보존 |
| 4 | [Ghostty](https://ghostty.org/docs/install/binary) | 셸 명령을 입력하고 실행하는 터미널 | Homebrew의 `ghostty` cask가 제공하는 버전 설치 |
| 5 | [Node.js + npm](https://formulae.brew.sh/formula/node@24) | JavaScript 실행과 패키지 관리 | `node@24`로 Node.js 24.x와 함께 제공되는 npm 설치 |
| 6 | [Python + uv](https://docs.astral.sh/uv/guides/install-python/) | Python 실행, 패키지와 가상환경 관리 | Homebrew의 `uv`, uv로 Python 3.14.x 설치 |
| 7 | [GitHub CLI (`gh`)](https://formulae.brew.sh/formula/gh) | GitHub 저장소와 Pull Request 작업 | Homebrew의 `gh`, 로그인은 별도 진행 |

고정 스펙은 **설치할 도구 묶음**을 뜻합니다. 정상 실행되는 기존 버전은 유지하며, 새 Node.js와 Python에만 위 버전 계열을 적용합니다. 패치 버전까지 고정하지 않으며 실제 버전과 경로는 `--check` 결과로 확인합니다. GitHub Desktop은 포함하지 않습니다.

macOS 개발 도구의 `/usr/bin/python3`는 사용자용 Python과 구분합니다. 새 Python은 uv가 관리하는 `python3.14`로 제공하고 시스템 Python이나 기존 버전 관리자의 기본 명령을 바꾸지 않습니다. VS Code는 앱 경로로 확인하므로 Cursor의 `code` 명령을 VS Code로 판단하지 않습니다.

실행 여부 확인은 보안 취약점 검사나 최신 버전 판정이 아닙니다. 세부 설치와 재실행 정책은 [CONTRIBUTING](../language/ko/CONTRIBUTING.md#라이트-실행)에 정리합니다.

## Windows 고정 도구 구성

패키지 ID는 [Microsoft WinGet manifest 저장소](https://github.com/microsoft/winget-pkgs/tree/master/manifests)를 기준으로 합니다. 패치 버전은 설치 시 소스에서 제공하는 값을 따릅니다.

| 순서 | 도구 | 역할 | 새 설치 정책 |
| --- | --- | --- | --- |
| 1 | WinGet | 패키지 관리 | 없는 경우 현재 사용자용 Microsoft.WinGet.Client 복구 |
| 2 | Git | 버전 관리 | WinGet Git.Git |
| 3 | VS Code | 편집기 | WinGet Microsoft.VisualStudioCode, 사용자 범위 |
| 4 | Windows Terminal | 터미널 | WinGet Microsoft.WindowsTerminal |
| 5 | Node.js + npm | JavaScript 실행 | OpenJS.NodeJS.LTS의 24.x 중 최신 값을 정확한 버전으로 설치 |
| 6 | Python + uv | Python 실행과 환경 관리 | WinGet astral-sh.uv, 이후 uv python install 3.14 |
| 7 | GitHub CLI | GitHub 연동 | WinGet GitHub.cli, 로그인은 직접 설정 |

정상 실행되는 기존 버전은 유지합니다. LTS 패키지가 더 높은 주 버전을 가리켜도 새 Node.js는 24.x로 제한합니다. Store의 Python 별칭은 설치로 인정하지 않습니다. Node/npm 부분 설치와 실행 오류는 중단하고, Python/uv는 없는 구성 요소만 보완합니다. 사용자 PATH를 백업한 뒤 필요한 실행 경로만 뒤에 추가합니다. 시스템 PATH, 프로필, 터미널 설정, Git 사용자 정보와 인증은 유지합니다. 두 플랫폼은 영문 메시지와 같은 옵션 이름을 사용합니다. Windows 동작은 [install.ps1](../installers/windows/install.ps1)과 [tools.ps1](../installers/windows/tools.ps1)에 구현합니다.

## 기술 방향

**Shelter Lite 0.2.0은 macOS와 Windows 설치기를 각각 제공합니다.** macOS는 macOS 15 이상과 기본 Apple Silicon 환경, Windows는 Windows 11 x64와 기본 64비트 Windows PowerShell 5.1이 대상입니다. [Windows 구현과 실기기 검증 항목](plans/windows-lite.md)을 참고하세요. 이번 Windows 버전은 Windows 10, Windows Server, ARM64와 32비트 프로세스를 지원하지 않습니다.
라이트는 macOS 기본 Bash 또는 Windows 기본 PowerShell을 사용하며 Node.js와 Python 사전 설치가 필요 없습니다. Python CLI는 개발 시 Python 3.14 이상을 사용하고 명령은 표준 라이브러리 `argparse`로 구성합니다. 실행 파일 패키징 도구는 미정입니다. 웹사이트 기술은 아직 검토 중입니다.

| 영역                 | 검토 기술                                                                                                                                                                                | 역할                                        | 상태                                   |
| -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------- | -------------------------------------- |
| macOS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | 라이트 설치와 셸 설정 | Apple Silicon, zsh/bash. Intel과 Rosetta 제외 |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | 고정 라이트 설치, WinGet, 사용자 PATH | x64와 Windows PowerShell 5.1 구현, 깨끗한 PC의 전체 설치 검증 필요 |
| 웹사이트와 정보 수집 | 미정                                                                                                                                                                                     | 보안 정보 수집, 조회와 사용자 화면          | 기술 선정 전                           |
| CLI 본체             | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white)                                                                                      | 상태 확인, 알림, 업데이트 처리              | Python 3.14 이상, 도움말과 버전 진입점만 구현                   |
| CLI 개발 도구        | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | 명령 구성, Python 환경과 의존성 관리        | uv는 개발용으로 채택, 명령은 표준 `argparse` 사용, Typer는 후보                        |
| Shelter Lite      | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | 고정 스펙의 최초 설치와 실행 환경 준비 | 구현됨, Bash 3.2.57로 검사 |
| macOS 배포           | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black)                                                                                | CLI 설치와 CLI 자체 업데이트                | 배포 후보                              |

지원 조건과 설치 정책의 근거 파일은 [install.sh](../installers/macos/install.sh), [tools.sh](../installers/macos/tools.sh)입니다. 최소 운영체제는 [Homebrew 설치 요구사항](https://docs.brew.sh/Installation)을 기준으로 제한합니다. 현재 실기기 확인은 macOS 26.6.2의 미리보기까지이며, 지원 범위 전체의 실제 설치를 검증한 것은 아닙니다.

## 개발 계획

1. **Shelter Lite 검증:** 환경 확인, 고정 스펙 설치와 결과 확인을 구현했습니다. 새 Mac에서 실제 설치, 터미널 재시작과 재실행을 검증한 뒤 배포합니다.
2. **CLI 연결:** PC의 설치 상태와 별도 웹사이트의 보안 정보를 연결하고, 해당 환경에 필요한 업데이트를 알립니다.
3. **업데이트와 확장:** 적용 결과 확인과 실패 대응을 구현하고, 도구 통합 설치를 확장합니다.

라이트는 최초 설치부터 시작하고, 정식 CLI는 이후 확장합니다. 세부 기능 범위와 자동 업데이트 정책은 미정입니다.
두 버전은 이 저장소에서 관리합니다. 웹사이트 코드는 이 저장소에 포함하지 않습니다.

아래 보안 정보 연동은 정식 CLI의 개발 계획입니다. 아직 실행 가능한 기능은 아닙니다.

```text
웹사이트에서 보안 이슈와 업데이트 정보 확인
  → CLI로 내 PC의 소프트웨어와 버전 확인
  → 내 환경에 해당하는 업데이트 알림
  → 필요한 업데이트 적용
  → 적용 결과와 재시작 필요 여부 확인
```

업데이트의 자동 적용 여부, 사용자 확인 방식과 알림 채널은 설계 단계에서 결정합니다.
정식 CLI 명령어는 구현된 동작을 검증한 뒤 안내합니다.

## 저장소 구조

### 현재 구조

현재 생성한 디렉터리, 실행 코드와 문서입니다.

```text
shelter/
├── .github/
│   └── workflows/
│       ├── validate.yml # macOS / Windows
│       └── release.yml # 릴리스 검사, 패키징과 파일 첨부
├── docs/
│   ├── specification.md
│   ├── specification.ko.md
│   ├── specification.jp.md
│   └── plans/
│       ├── readme-usage.md # README 사용법 중심 정리 계획
│       ├── shelter-cli.md # CLI 탐색, 업데이트 조회와 배포 계획
│       └── windows-lite.md # Windows 구현과 실기기 검증 항목
├── dist/             # 생성 결과, Git 관리 제외
│   ├── shelter-lite-macos.sh
│   ├── shelter-lite-macos.sh.sha256
│   ├── shelter-lite-macos.zip
│   ├── shelter-lite-macos.zip.sha256
│   ├── shelter-lite-windows.ps1
│   ├── shelter-lite-windows.ps1.sha256
│   ├── shelter-lite-windows.zip
│   ├── shelter-lite-windows.zip.sha256
│   └── VERSION
├── installers/
│   ├── macos/        # 라이트와 향후 정식 버전의 macOS 설치기
│   │   ├── build.sh   # 셸 파일과 더블클릭용 ZIP 생성
│   │   ├── install.sh # 진입점, 고정 스펙과 설치 순서
│   │   ├── messages.sh # 영문 메시지, 오류 문구, 색상과 출력 형식
│   │   ├── tools.sh   # 도구 확인, 설치, 셸 설정
│   │   └── tests/
│   │       └── test.sh # 임시 환경에서 실행하는 설치기 테스트
│   └── windows/
│       ├── build.ps1
│       ├── install.ps1
│       ├── launch.cmd
│       ├── messages.ps1
│       ├── tools.ps1
│       └── tests/
│           └── test.ps1
├── src/
│   └── shelter/      # Python CLI 패키지
│       ├── __init__.py
│       ├── cli.py    # `shelter` 진입점: 도움말과 버전
│       └── providers/ # 패키지 관리자별 조회 처리 위치
│           └── __init__.py
├── tests/            # CLI 테스트, 설치기 테스트와 구분
│   └── test_cli.py
├── pyproject.toml    # Python 패키지 정보와 `shelter` 진입점
├── uv.lock           # 확정된 개발 의존성
├── scripts/
│   ├── version.ps1
│   └── version.sh    # 제품 버전 형식 검증과 파일 읽기
├── language/
│   ├── ko/
│   │   ├── README.md       # 한국어 제품 소개, 구성과 개발 방향
│   │   └── CONTRIBUTING.md # 한국어 관리자용 개발과 배포 안내
│   └── jp/
│       ├── README.md       # 일본어 제품 소개, 구성과 개발 방향
│       └── CONTRIBUTING.md # 일본어 관리자용 개발과 배포 안내
├── README.md         # 영문 제품 소개, 구성과 개발 방향
├── CONTRIBUTING.md   # 영문 관리자용 개발과 배포 안내
├── VERSION           # 제품 버전의 단일 관리 지점
└── LICENSE           # MIT 라이선스
```

### 구성 요소의 역할

Windows는 [messages.ps1](../installers/windows/messages.ps1)을 설치기, 빌드와 테스트의 메시지 SSOT로 사용합니다. [build.ps1](../installers/windows/build.ps1)은 실행 소스, MIT 라이선스와 루트 `VERSION`을 단일 `.ps1`에 포함하고, ZIP에는 `.cmd` 실행기와 `VERSION`을 추가합니다. [version.ps1](../scripts/version.ps1)과 `version.sh`는 설치기와 독립적으로 같은 제품 버전 규약을 구현합니다.

Windows 로직과 패키징은 격리 테스트로 확인하며 실제 Windows 11 설치, WinGet 복구, UAC와 내려받은 파일의 실행은 깨끗한 실기기에서 추가 검증해야 합니다. CI는 Windows의 기본 PowerShell 5.1을 검사합니다. Windows Server runner는 모의 테스트용이며 설치 지원 대상이 아닙니다.

[messages.sh](../installers/macos/messages.sh)는 macOS 설치기와 테스트가 공유하는 영문 안내, 경고, 오류, 도움말과 터미널 출력 형식의 단일 관리 지점(SSOT)입니다. 실패 판단, 설치 중단과 종료 코드는 `install.sh`와 `tools.sh`에서 담당합니다.

[build.sh](../installers/macos/build.sh)는 실행 소스와 MIT 라이선스를 `dist/shelter-lite-macos.sh` 하나로 묶습니다. 생성 파일에도 같은 메시지와 설치 로직을 포함하며, 수정은 원본에서 하고 다시 생성합니다. 같은 실행 파일을 `Shelter Lite.command`라는 이름으로 `dist/shelter-lite-macos.zip`에 담아 터미널에서 열 수 있게 제공합니다.

라이트는 `install.sh`에서 고정 스펙 전체의 설치를 시작하고 `tools.sh`의 함수를 호출합니다. 정식 버전을 제공할 때도 같은 진입점에 정식 CLI 설치 흐름을 연결할 계획입니다. 현재 `--mode full`은 준비 중 안내와 함께 종료합니다. 버전별 설치 디렉터리나 도구별 하위 폴더는 미리 나누지 않습니다.

정식 CLI의 구조는 `src/shelter/`, 관리자별 조회 처리는 `providers/`, CLI 테스트는 루트 `tests/`에 준비했습니다. `pyproject.toml`과 도움말, 버전을 출력하는 `shelter` 진입점이 있습니다. 도구 탐색, 업데이트 조회와 Lite 호출은 미구현입니다. 모듈 책임과 사전 설치 없는 배포 방향은 [CLI 계획](plans/shelter-cli.md)을 따릅니다. 웹사이트와 수집 서비스, 공통 데이터 규격의 구조는 연동 범위가 정해지면 검토하며, 현재 설치기 구조에 포함하지 않습니다.
공통 코드나 도구별 처리가 실제로 커질 때 파일을 분리합니다. 릴리스 workflow는 해당 버전을 검증하고 패키징하며, 추가 검사와 상세 문서는 기능에 맞춰 확장합니다.
디렉터리를 만드는 시점과 문서 갱신 절차는 [CONTRIBUTING의 디렉터리 추가와 변경](../language/ko/CONTRIBUTING.md#디렉터리-추가와-변경)을 따릅니다.

## 명령 참조

| 옵션 | 동작 |
| --- | --- |
| 옵션 없음 | 라이트 전체 초기 설정 |
| `--dry-run` | 설치 계획만 확인, 다운로드와 설정 변경 없음 |
| `--check` | 전체 도구의 실행 상태 확인, 다운로드와 설정 변경 없음 |
| `--version`, `-V` | 환경 변경 없이 Shelter Lite 제품 버전 표시 |
| `--mode lite` | 기본값과 동일 |
| `--mode full` | 준비 중 안내 후 종료, 설치하지 않음 |
| `--color auto\|always\|never` | 자동 색상, 항상 색상(기본값) 또는 무색 출력 |
| `--color` | 이번 실행에 색상 강제 적용, `--color always`와 동일 |
| `--help` | 도움말 |

종료 코드는 성공 `0`, 미설치 상태 또는 실행/설치 오류 `1`, 잘못된 옵션이나 미지원 환경 `2`, Ctrl+C 중단 `130`입니다. `--check`와 `--dry-run`은 함께 사용하지 않습니다. 미리보기에서 정상적으로 계획을 만들면 미설치 도구가 있어도 `0`으로 종료합니다.

Ctrl+C의 `130`은 macOS 기준이며 Windows 중단은 PowerShell/CMD 호스트 동작을 따릅니다. `0`, `1`, `2`는 두 플랫폼에서 공통입니다.
