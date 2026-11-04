# 개발과 유지보수

| English | 한국어 | 日本語 |
| --- | --- | --- |
| [English](../../CONTRIBUTING.md) | **현재 문서** | [日本語](../jp/CONTRIBUTING.md) |

Shelter 관리자를 위한 개발, 문서 작성, 검증과 배포 절차를 안내합니다.
제품 목적, 구성과 기술 방향은 [한국어 README](./README.md)를 기준으로 합니다.

현재 macOS와 Windows용 Shelter Lite, 격리된 테스트, 스크립트와 더블클릭용 ZIP 패키징, 릴리스 자동 빌드를 제공합니다. 정식 CLI는 아직 준비 전입니다.

## 목차

- [기여 정책](#기여-정책)
- [개발 준비](#개발-준비)
- [라이트 실행](#라이트-실행)
- [Windows 라이트](#windows-라이트)
- [디렉터리 추가와 변경](#디렉터리-추가와-변경)
- [작업 절차](#작업-절차)
- [문서 작성](#문서-작성)
- [구현과 검증](#구현과-검증)
- [커밋과 게시](#커밋과-게시)
- [배포](#배포)

## 기여 정책

현재 외부 Pull Request와 Issue를 받지 않으며, 두 기능은 비활성화되어 있습니다. 개발 방향의 결정과 배포는 저장소 쓰기 권한을 가진 관리자가 담당합니다.

소프트웨어에는 계속 [MIT 라이선스](../../LICENSE)가 적용됩니다. 이 기여 정책은 라이선스가 허용하는 사용, 수정과 재배포를 제한하지 않습니다.

관리자는 기술 스택 선정, 지원 운영체제 확대와 큰 기능 추가의 범위를 구현 전에 정하고, 다음 내용을 기록합니다.

- 어떤 사용자가 어떤 상황에서 겪는 문제인지
- 기대하는 동작과 현재 동작의 차이
- 관련 공지, 재현 방법이나 참고 자료

보안 공지의 내용과 Shelter 자체의 결함은 구분해 주세요. 재현 자료에 토큰, 인증 정보나 개인 경로가 포함됐다면 제거해 주세요.

## 개발 준비

### 저장소 받기

Git이 있다면 저장소 루트에서 다음과 같이 시작합니다. 이미 내려받았다면 이 단계는 건너뜁니다.

```bash
git clone https://github.com/4BFC/shelter.git
cd shelter
git status --short
```

Git이 없는 새 Mac에서는 GitHub 저장소의 **Code → Download ZIP**으로 전체 소스를 받아 압축을 풀고, 터미널에서 해당 폴더로 이동합니다. `install.sh`, `messages.sh`, `scripts/version.sh`, `tools.sh`와 루트 `VERSION` 파일을 포함한 저장소 구조를 유지해야 합니다.

단일 배포 파일은 이 네 스크립트와 제품 버전을 내부에 포함합니다. 생성과 실행 방법은 [배포](#배포)를 참고하세요.

### 실행 환경

macOS 설치기의 대상은 **macOS 15 이상, Apple Silicon, zsh 또는 bash**입니다. Intel, Rosetta와 Windows에서는 설치하지 않고 종료합니다. macOS 기본 `/bin/bash`로 실행하며 Bash 3.2.57에서 검사했습니다. Python이나 Node.js를 미리 준비할 필요는 없습니다.

설치에는 인터넷 연결과 Homebrew 설치 권한이 필요합니다. 공식 Homebrew 설치기가 관리자 인증과 Xcode Command Line Tools 설치를 요청할 수 있습니다. **전체 스크립트를 `sudo`로 실행하지 마세요.** [Homebrew 설치 요구사항](https://docs.brew.sh/Installation)을 참고하세요.

정식 CLI는 아직 구현하지 않았습니다. 향후 런타임 의존성을 추가할 때 버전, 의존성 선언, 잠금 파일과 실행 명령을 함께 기록합니다.

## 라이트 실행

아래 명령은 모두 저장소 루트에서 실행합니다. 먼저 변경 없이 계획을 확인할 수 있습니다.

```bash
/bin/bash installers/macos/install.sh --dry-run
```

초기 설정을 시작하는 명령은 다음과 같습니다. 도구 선택이나 제외 옵션 없이 [라이트 고정 설치 스펙](../../docs/specification.ko.md#라이트-고정-설치-스펙) 전체를 준비합니다.

```bash
/bin/bash installers/macos/install.sh
```

설치와 `--dry-run` 시작 시 Shelter Lite ASCII 로고가 한 번 표시됩니다. 기본 화면에는 초기 설정을 시작한다는 안내와 최종 **설치 완료 또는 설치 실패**를 요약하고, 짧은 설명과 다음 행동을 함께 표시합니다. Homebrew가 없는 Mac에서는 공식 최초 설치기의 확인과 관리자 인증 안내를 터미널에 직접 표시합니다.

| 메시지 | 표시하는 내용 |
| --- | --- |
| `● note:` | 초기 설정 시작, 실패 후 로그 확인과 재실행 안내 |
| `● success:` | 개발 도구 준비가 완료되었다는 설명 |
| `● error:` | 설치나 설정을 완료하지 못한 이유 |
| `● warning:` | 새 실행 경로의 반영 대기, 실패 후 진행된 설치나 설정 변경이 남는다는 안내 |

경고는 해당 상황에서만 표시합니다. 새 실행 경로가 없다면 반영 대기 경고를 생략하고, 설치나 셸 설정을 시작하기 전에 중단했다면 변경이 남는다는 경고도 생략합니다. 색상을 꺼도 메시지 분류와 본문은 그대로 표시합니다.

최종 결과는 구분선 없이 제목과 메시지로 표시합니다. 메시지 앞에 `●`를 붙이고, 접두어는 대괄호 없이 영문 소문자와 콜론으로 표시합니다. 미리보기, 설치 흐름 테스트와 실제 설치기의 메시지, 결과 제목, 도움말, 로그는 영문으로 표시합니다. **일반 메시지는 `●`에만 상태 색상을 적용하고 접두어와 본문은 터미널 기본 색상을 사용합니다.** 성공은 초록색, 실패와 오류는 빨간색, 안내는 청록색, 경고는 노란색입니다. `Installation complete`(설치 완료), `Installation failed`(설치 실패), `Check required`(확인 필요) 같은 결과 제목에는 글자 전체에 상태 색상을 적용합니다. 일반 제목과 상세 표의 본문에는 색상을 지정하지 않으며, 표도 행 앞의 `●`로 상태 색상을 표시합니다.

구역 제목, 표 헤더, 설치 예정 항목과 설정 경로는 기존 들여쓰기 대신 `PUA 아이콘 + 공백 1칸`으로 표시합니다. 아이콘은 [Nerd Fonts v3.5.0](https://github.com/ryanoasis/nerd-fonts/blob/v3.5.0/glyphnames.json)의 Font Awesome 매핑을 기준으로 `messages.sh`의 `shelter_icon`에서 관리합니다. 아이콘을 표시하려면 해당 매핑을 지원하는 터미널 폰트나 대체 폰트가 필요합니다. 상태 메시지와 도구 행의 기존 `●`, 색상, 간격은 유지합니다.

설치기와 테스트는 `--dry-run`, `--check`를 포함하여 기본으로 색상을 사용합니다. 색상 옵션을 추가하지 않아도 되며, 터미널 설정 자체는 변경하지 않습니다.

```bash
/bin/bash installers/macos/install.sh
```

기본값인 `always`는 `NO_COLOR`, `TERM=dumb`, 출력 리다이렉션 여부와 관계없이 색상을 출력합니다. 터미널 판별과 `NO_COLOR` 설정을 따르려면 `--color auto`, 색상을 끄려면 `--color never`를 사용합니다. 출력 뷰어가 ANSI 색상을 지원하지 않으면 `always`를 사용해도 색상이 보이지 않을 수 있습니다.

설치기와 테스트 명령은 값 없는 `--color`도 계속 지원하며, 현재 기본값인 `--color always`와 같습니다. 설치 계획도 추가 옵션 없이 색상으로 확인할 수 있습니다.

```bash
/bin/bash installers/macos/install.sh --dry-run
```

실행 결과와 설치 후 할 일은 [README 사용법](./README.md#사용법)을, 전체 옵션과 종료 코드는 [명령 참조](../../docs/specification.ko.md#명령-참조)를 참고하세요. 저장소에서 상태를 확인할 때는 `/bin/bash installers/macos/install.sh --check`를 사용합니다.

설치 로그는 소유자만 읽고 쓸 수 있으며 색상 코드를 포함하지 않습니다.

### 기존 환경과 재실행

- 정상 실행되는 기존 도구는 재설치하거나 버전을 맞추기 위해 직접 업그레이드하지 않습니다. 새 Node.js는 `node@24`, 새 Python은 uv의 `3.14` 계열로 설치합니다. 패치 버전과 나머지 도구의 버전은 설치 시 패키지 관리자가 제공하는 버전을 따릅니다.
- Node.js와 npm 중 하나만 있거나 기존 명령 실행에 실패하면 변경 전에 중단합니다. Python과 uv는 없는 구성 요소만 설치할 수 있습니다. `/usr/bin/python3`는 macOS 개발 도구용으로 유지하고 별도 사용자용 Python을 준비합니다.
- uv의 Python 조회는 네트워크와 기존 캐시를 사용하지 않습니다. 조회 오류는 `Check required`(확인 필요)로 표시하고, 정상 조회에서 설치된 Python이 없을 때만 설치 대상으로 판단합니다.
- VS Code는 `/Applications` 또는 `~/Applications`의 앱으로 확인합니다. [Homebrew의 `--no-binaries`](https://docs.brew.sh/Manpage)로 앱을 설치하고, 기존 `code` 명령이 Cursor 등 다른 편집기에 연결되어 있으면 보존합니다. 이 경우 VS Code는 응용 프로그램 폴더에서 실행합니다.
- Ghostty는 `PATH`에 `ghostty` 명령이 없어도 `/Applications/Ghostty.app` 또는 `~/Applications/Ghostty.app`에서 확인합니다. 정상 실행되는 앱은 유지하고, 없으면 `brew install --cask ghostty`로 설치합니다. 앱이 손상되었거나 버전 확인에 실패하면 중단합니다. Ghostty 설정, 폰트와 기본 터미널은 변경하지 않습니다.

사용자 설정과 재실행 절차는 [README 사용법](./README.md#사용법)을 참고하세요. 오류가 나면 뒤의 설치를 멈추며 완료된 변경은 남습니다. 새 패키지에 필요한 의존성 변경은 Homebrew가 처리합니다.

개별 `brew install` 실행에는 자동 업데이트, 설치 후 정리, 기존 설치 대상의 자동 업그레이드를 끄는 환경변수를 적용합니다. 의존성 호환성 처리는 Homebrew에 맡깁니다. 관련 동작은 [Homebrew 명령 문서](https://docs.brew.sh/Manpage)를 기준으로 합니다.

### 셸 설정과 백업

필요한 실행 경로를 현재 `PATH`의 뒤에 추가해 nvm, mise, pyenv 등 기존 설정의 우선순위를 보존합니다. 추가한 경로가 있으면 다음 위치에 저장하고 셸 설정에 한 번만 연결합니다.

| 파일 | 변경 내용 |
| --- | --- |
| `${XDG_CONFIG_HOME:-$HOME/.config}/shelter/env.sh` | Shelter가 추가한 실행 경로, 기존 사용자 파일은 덮어쓰지 않음 |
| `${ZDOTDIR:-$HOME}/.zshrc` | zsh 사용자의 환경 파일 로드 구문 |
| `$HOME/.bashrc`, `$HOME/.bash_profile` | bash 사용자의 환경 파일 로드 구문 |

기존 파일을 변경하기 전 환경 파일과 같은 디렉터리에 `env.sh.backup.*` 또는 `shell.backup.*`으로 백업하고 경로를 설치 로그에 기록합니다. 셸 설정은 기존 내용을 유지한 채 로드 구문을 덧붙입니다. 오류로 일부 설정만 반영된 경우에도 완료된 변경과 백업은 남습니다.

새 터미널을 열어 경로 설정을 적용합니다. 현재 터미널에 바로 적용하려면 설치 로그에 기록된 `source` 명령을 실행합니다. 실행 중인 편집기는 재시작해야 새 환경을 사용합니다. 새 Python은 [uv의 버전별 실행 파일 정책](https://docs.astral.sh/uv/guides/install-python/)에 따라 `python3.14`로 제공하며, 시스템의 `python3`나 `python`을 교체하지 않습니다.

백업 복구가 필요하면 로그에 기록된 원본 경로와 백업을 비교한 뒤 복원합니다. 다른 셸 설정을 유지하려면 `# Shelter Lite`가 붙은 로드 구문만 제거할 수도 있습니다. 이 작업은 설치된 프로그램을 삭제하지 않습니다.

## Windows 라이트

저장소 루트에서 PowerShell로 다음 명령을 실행합니다. Windows 11 x64와 기본 64비트 Windows PowerShell 5.1을 대상으로 합니다. 관리자 권한으로 시작하지 않으며, 개별 패키지가 UAC 인증을 요청할 수 있습니다. Node.js와 Python 사전 설치는 필요 없습니다.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --dry-run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --version
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Color never
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Preview warning
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Install failure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/build.ps1
```

옵션 없는 `install.ps1`은 Windows 고정 스펙 전체를 설치합니다. `--dry-run`, `--check`, `--version`, `--mode lite`, `--color`와 종료 코드는 macOS와 같습니다. Ctrl+C는 호스트의 기본 중단 동작을 따릅니다. `-Preview`는 `notification`, `warning`, `failure`, `success`를, `-Install`은 `success`, `failure`, `dry-run`을 받습니다. 실행 흐름 테스트는 임시 파일과 모의 명령만 사용하며 실제 도구를 설치하지 않습니다.

`messages.ps1`은 설치, 빌드와 테스트가 공유하는 Windows 메시지 SSOT입니다. macOS와 같은 영문 접두사, 상태 점의 색상, 결과 제목, PUA 아이콘과 기본 `always` 색상 정책을 사용하며 Bash를 요구하지 않습니다. `scripts/version.ps1`은 `scripts/version.sh`와 같은 SemVer 규약으로 루트 `VERSION`을 읽습니다.

WinGet이 없으면 PowerShell Gallery를 통한 공식 현재 사용자용 `Microsoft.WinGet.Client` 복구 경로를 사용합니다. 패키지 ID와 Windows별 정책은 기술 사양에 정리합니다. 소스와 패키지 약관에 동의하고, 정확한 ID, `winget` 소스와 `--no-upgrade`를 사용합니다. Node.js는 최신 주 버전을 그대로 설치하지 않고 제공되는 24.x 중 선택합니다. 기존 정상 버전은 유지하며 Node/npm 부분 설치나 실행 오류는 사전 검사에서 중단합니다. Store의 Python 별칭은 제외합니다. Python과 uv는 없는 구성 요소만 보완하며, uv 조회는 오프라인으로 실행하고 새 Python은 `3.14`를 설치합니다.

원본 사용자 PATH를 ACL로 보호한 JSON에 백업한 뒤 필요한 실행 경로만 끝에 추가합니다. 기존 환경 변수 참조와 레지스트리 값 형식을 유지합니다. 시스템 PATH와 PowerShell 프로필은 수정하지 않습니다. `%LOCALAPPDATA%\Shelter\logs`의 로그와 PATH 백업은 현재 사용자와 SYSTEM만 접근하도록 제한합니다. 설치 후 터미널과 편집기를 다시 시작하고, Git 사용자 정보와 GitHub 로그인은 직접 설정합니다.

빌드는 `dist/`에 `shelter-lite-windows.ps1`, `shelter-lite-windows.zip`, 각각의 `.sha256`과 `VERSION`을 생성합니다. ZIP에는 `Shelter Lite.cmd`, 단일 `.ps1`과 `VERSION`이 들어갑니다. 두 실행 파일은 같은 폴더에 유지합니다. `.ps1`에는 제품 버전과 MIT 라이선스가 포함됩니다. 같은 도구 환경에서 재현 가능하도록 ZIP 시간을 고정합니다. 다른 출력 경로는 `build.ps1 -OutputDirectory "C:\path with spaces"`로 지정합니다.

실행기는 프로필 없이 기본 64비트 Windows PowerShell을 시작하고, 현재 프로세스에만 실행 정책을 지정합니다. 종료 코드를 유지하고 인자 없이 실행했을 때만 창을 대기시킵니다. 조직 정책은 우회하지 않습니다. 스크립트는 서명되지 않았습니다. 격리 테스트만으로 SmartScreen, App Installer 복구, UAC와 깨끗한 Windows 11 PC의 전체 설치가 검증되지는 않습니다. `v0.2.0`을 게시하기 전에 실기기 검증 항목을 완료하세요.

## 디렉터리 추가와 변경

전체 배치와 각 경로의 책임은 [기술 사양의 저장소 구조](../../docs/specification.ko.md#저장소-구조)를 기준으로 합니다.
실행 코드는 `install.sh`, `messages.sh`, `scripts/version.sh`, `tools.sh`와 루트 `VERSION`으로 구성하며, `build.sh`로 패키징하고 `tests/test.sh`로 원본과 단일 배포 파일을 검증합니다. `dist/`는 생성 결과를 담으며 Git 관리에서 제외합니다. 이후 경로는 해당 기능을 구현할 때 필요한 만큼 추가합니다.

1. **라이트의 설치 흐름을 관리합니다.** `installers/macos/install.sh`에 환경 확인, 고정 스펙과 설치 순서를 두고, `tools.sh`에 도구별 상태 확인, 설치와 셸 설정 함수를 둡니다. 별도 `lib/`, `tools/`, `profiles/` 디렉터리는 실제 분리 필요성이 생기면 검토합니다.
2. **정식 버전의 설치를 연결합니다.** 정식 CLI와 배포물이 준비되면 같은 `install.sh`의 `full` 모드에 설치 흐름을 추가하고 도구 설치 함수는 재사용합니다. 현재는 준비 중 안내 후 종료합니다.
3. **정식 CLI 본체는 별도로 구현합니다.** Python을 채택하면 본체는 `src/shelter/`, Python 테스트는 루트 `tests/`, 패키지 설정은 루트 `pyproject.toml`에 둡니다. 이 경로들은 아직 생성하지 않았습니다. 설치기에 지속적인 보안 알림과 업데이트 관리 기능을 중복 구현하지 않습니다.

Shell 설치기 테스트는 `installers/macos/tests/`에서 관리합니다. 버전별 동작을 추가할 때 공통 설치 흐름과 각 버전의 동작을 함께 확인하고, 실제 실행 위치와 명령을 이 문서에 기록합니다.
웹사이트는 이 저장소 밖에서 관리합니다. 정보 수집 서비스와 데이터 형식은 연동 범위를 정한 뒤 구조를 정합니다. Windows 스크립트, 실행기, 테스트와 패키징은 `installers/windows/`에서 관리합니다. [Windows 구현과 실기기 검증 항목](../../docs/plans/windows-lite.md)을 참고하세요.

구조를 적용하거나 바꿀 때는 다음 내용을 같은 변경에 반영합니다.

- 기술 사양의 **현재 구조**에 실제 추가한 경로를 반영하고, **구성 요소의 역할**에 남은 범위를 표시합니다.
- CONTRIBUTING에 해당 구성 요소의 설치, 실행과 검증 명령을 작업 디렉터리와 함께 기록합니다.
- 상세 설계나 별도 계획 문서가 필요해지면 `docs/`에 추가하고 관련 문서에서 연결합니다. 문서 분류를 위한 하위 디렉터리는 미리 만들지 않습니다.

라이트와 정식 버전의 설치기는 같은 경로에서 관리하고, 설치기와 정식 CLI 본체의 책임을 구분합니다. Homebrew 배포를 선택하면 Formula와 Tap의 관리 위치를 배포 절차에서 별도로 정합니다.

## 작업 절차

1. README에서 사용법을, `docs/`의 기술 사양에서 현재 구현 범위를 확인합니다.
2. 변경할 내용을 정하고 작업 브랜치를 만듭니다.
3. 관련 문서와 코드를 함께 수정합니다.
4. 아래 검증 기준에 따라 확인하고 diff를 검토합니다.
5. 변경 목적과 검증 결과를 기록하고, 관리자의 승인에 따라 커밋하고 push합니다.

작업 브랜치 이름의 예시입니다. 동일한 이름의 브랜치가 있다면 작업에 맞는 다른 이름을 사용합니다.

```bash
git switch -c docs/update-introduction
```

이미 진행 중인 변경은 보존하고, 요청이나 제안과 관계없는 수정은 같은 변경에 섞지 않습니다.

## 문서 작성

**README**는 제품 소개, 스펙 표, 설치와 사용법을 안내합니다. 상세 사양, 기술 선택, 개발 계획과 저장소 구조는 `docs/`에서 관리합니다.
**CONTRIBUTING**은 관리자용 소스 실행 준비, 개발, 검사, 커밋과 배포 방법을 담으며 현재 기여 정책도 안내합니다.

영문 README와 CONTRIBUTING은 저장소 루트, 한국어 문서는 `language/ko/`, 일본어 문서는 `language/jp/`에서 같은 내용과 구조로 관리합니다. 각 문서 상단의 언어 표는 같은 문서의 다른 언어 버전으로 연결합니다. 이 문서의 실행 명령은 저장소 루트를 기준으로 합니다.

- README는 [Standard Readme 규격](https://github.com/RichardLitt/standard-readme/blob/main/spec.md)의 섹션 구조를 따릅니다. 목차를 유지하고 라이선스를 마지막에 둡니다. 번역 파일은 표준의 `README.<언어>.md` 명명 대신 이 프로젝트의 `language/<언어>/README.md` 구조로 관리합니다.
- 짧은 소개 문구는 README, 향후 패키지 메타데이터와 GitHub 저장소 설명이 일치하도록 관리합니다.
- 현재 동작과 개발 계획을 구분합니다. 아직 없는 명령, 디렉터리와 배포 주소를 사용 가능한 것처럼 적지 않습니다.
- 비개발자가 읽는 설명에서는 문제와 다음 행동을 먼저 쓰고, 전문 용어는 처음 등장할 때 설명합니다.
- 기술 스펙에는 확인한 버전과 근거 파일을 함께 적습니다. 버전이 정해지지 않았다면 `미정`으로 표시합니다.
- 보안 이슈와 업데이트 정보를 설명할 때 원문 출처, 확인 시점, 영향받는 버전과 수정 버전을 구분합니다. 확인하지 못한 내용은 추정으로 표시합니다.

상세 설계가 길어지면 `docs/`의 담당 문서로 분리하고 README에서 연결합니다. 문서가 쌓이면 주제에 맞춰 묶고, 같은 내용을 여러 파일에 복제하지 않습니다.

## 구현과 검증

### 안내 메시지 미리보기

공통 문구는 [messages.sh](../../installers/macos/messages.sh)에서 수정합니다. `shelter_copy`에 메시지 키와 고정 템플릿을 추가하고, `shelter_error install_failed "$name"`처럼 가변 값은 인자로 전달합니다. `shelter_error`는 stderr 출력과 실패 사유 저장을 담당하며, `return`이나 `exit`로 중단하는 시점은 호출부에서 결정합니다. 일반 안내는 `shelter_message <tone> <key> [arguments...]`, 시작, 경고, 성공, 실패의 공통 화면은 `shelter_notice`를 사용합니다. 내부 상태값과 표시 문구는 분리합니다. 테스트도 공통 메시지를 호출하지만, 예상 출력은 독립된 문자열로 유지하여 의도하지 않은 문구나 형식 변경을 검출합니다.

**각 상태의 표현과 설명만 확인하려면** 저장소 루트에서 `--preview` 뒤에 상태를 지정합니다. 색상은 추가 옵션 없이 기본으로 적용됩니다.

```bash
/bin/bash installers/macos/tests/test.sh --preview notification
/bin/bash installers/macos/tests/test.sh --preview warning
/bin/bash installers/macos/tests/test.sh --preview failure
/bin/bash installers/macos/tests/test.sh --preview success
```

| 상태 | `●` 색상 (결과 제목에도 적용) | 확인하는 메시지 |
| --- | --- | --- |
| `notification` | 청록색 | 초기 설정을 시작한다는 안내 |
| `warning` | 노란색 | 실행 경로 반영 대기와 터미널, 편집기를 다시 열라는 설명 |
| `failure` | 빨간색 | 설치 실패 제목과 오류 이유 예시 |
| `success` | 초록색 | 설치 완료 제목과 개발 도구 준비 완료 설명 |

미리보기는 실제 설치기와 공유하는 메시지 함수만 호출합니다. 설치 상태를 조회하거나 임시 파일을 만들지 않습니다. `--preview`만 입력하면 `success`를 표시합니다. 색상은 기본으로 적용됩니다. 사용자 터미널 설정을 따르려면 `--color auto`, 무색 출력을 확인하려면 `--color never`를 사용합니다.

### 설치 흐름 테스트

**실제 설치기의 전체 절차를 임시 환경에서 실행하려면** `--install`을 사용합니다.

```bash
/bin/bash installers/macos/tests/test.sh --install
```

도구가 없는 테스트 환경에서 Homebrew 준비부터 고정 스펙 설치, 결과 확인, 셸 설정까지 실제 설치기 코드를 실행합니다. 다운로드와 패키지 설치 명령은 가짜 도구로 대체하며, 실제 PC의 프로그램과 사용자 셸 설정은 바꾸지 않습니다. 테스트 파일과 로그는 종료 후 자동 정리합니다.

정식 옵션 표기는 `--install`이며, `--intall`도 같은 동작으로 처리합니다. 아래 상황 이름은 테스트 조건이며 실제 설치할 도구를 선택하는 옵션이 아닙니다.

```bash
# uv 설치 도중 실패하고 이후 설치를 멈추는 전체 흐름
/bin/bash installers/macos/tests/test.sh --install failure

# 테스트 환경의 설치 예정 안내
/bin/bash installers/macos/tests/test.sh --install dry-run
```

`--install success`는 기본 상황과 같습니다. 실패 상황에서는 내부 설치기의 종료 코드 `1`이 예상 결과입니다. 테스트 명령은 예상한 결과가 나오면 `0`, 예상과 다르면 `1`, 잘못된 옵션이면 `2`로 종료합니다. 예상과 다른 경우에만 테스트 오류를 별도로 표시합니다. `--preview`와 `--install`은 함께 사용할 수 없습니다.

현재 Mac의 실제 상태를 읽어 설치 계획을 확인하는 명령은 `install.sh --dry-run`입니다. 실제 초기 설정은 [라이트 실행](#라이트-실행)의 옵션 없는 명령으로 진행합니다.

### Shell 검증

저장소 루트에서 구문 검사와 임시 환경 테스트를 실행합니다. 별도 테스트 패키지가 필요하지 않습니다.

```bash
for script in scripts/*.sh installers/macos/*.sh installers/macos/tests/test.sh; do
  /bin/bash -n "$script" || exit 1
done
/bin/bash installers/macos/tests/test.sh
```

테스트는 Homebrew, 다운로드, 설치 명령과 환경 판별을 대체하고 임시 디렉터리에만 결과를 씁니다. 실제 프로그램이나 사용자 셸 설정을 변경하지 않습니다. 고정 스펙 설치, 기존 버전 보존, 재실행, 설치 실패, 잘못된 옵션, 미지원 환경, 설정 백업과 다른 편집기의 `code` 명령 보존을 검사합니다. 간결한 화면과 상세 로그의 분리, 로그 권한, `●`와 결과 제목의 색상 및 본문의 기본 색상, 상태별 미리보기, 설치 흐름 테스트의 격리와 종료 코드도 검사합니다. Ghostty는 `PATH`에 없는 기존 앱의 보존, 손상된 앱 감지, 설치 실패와 재시도, 설치 후 실행 검증도 검사합니다.

패키징 테스트는 체크섬, 동일 소스의 재현 가능한 출력, 파일 하나를 다른 경로로 옮긴 뒤 도움말 실행, 설치 없이 소스 로드를 검사합니다. 설치와 `--dry-run` 화면에서는 ASCII 로고가 한 번 표시되는지도 검사합니다. ZIP은 macOS에서 압축을 푼 뒤 실행 권한, 단독 실행, 종료 코드 유지와 동일 소스의 재현 가능한 압축 결과도 검사합니다.

지원되는 Mac에서는 다음 읽기 전용 명령도 확인합니다.

```bash
/bin/bash installers/macos/install.sh --help
/bin/bash installers/macos/install.sh --dry-run
/bin/bash installers/macos/install.sh --check
```

새 Mac에서 실제 다운로드와 설치가 끝나는지, Ghostty, 새 터미널과 VS Code에서 도구를 실행할 수 있는지, 재실행 때 설치와 설정이 중복되지 않는지 별도로 검증합니다. **현재 검증은 임시 환경 테스트와 macOS 26.6.2의 읽기 전용 실행까지입니다. 실제 초기 설치 전체를 검증하지는 않았습니다.**

### 문서와 diff 검증

저장소 루트에서 실행합니다.

```bash
git diff --check
git diff -- .gitignore README.md CONTRIBUTING.md language/ installers/macos/
git status --short
```

`git diff`에는 추적 중인 파일의 변경만 표시됩니다. 새 파일은 편집기에서 전체 내용을 별도로 확인합니다.

Markdown 미리보기에서 제목, 표, 코드 블록과 배지를 확인하고, 목차와 상대 링크를 직접 점검합니다.
라이선스 표시의 소유자와 연도는 [LICENSE](../../LICENSE)와 일치해야 합니다.

### 기능별 검증 기준

릴리스 workflow에서 Bash 구문 검사와 격리된 설치기 테스트를 실행합니다. 아래 기능을 추가할 때 필요한 정적 검사도 함께 추가합니다.

| 변경 영역       | 확인할 동작                                                                               |
| --------------- | ----------------------------------------------------------------------------------------- |
| 정보 수집       | 원문 출처와 확인 시점 보존, 중복 공지 처리, 수집 실패와 오래된 정보 표시                  |
| 영향 판단       | 영향 범위 안팎의 버전 구분, 수정 버전 구분, 알 수 없는 상태를 안전한 상태로 표시하지 않음 |
| PC 상태 확인    | 설치된 버전과 실제 실행 경로 구분, 관리 도구 간 충돌과 미지원 환경 표시                   |
| 설치와 업데이트 | 변경 대상과 결과 표시, 다운로드나 적용 실패 처리, 설정 백업과 복구 가능한 범위 확인       |
| 알림과 안내     | 문제, 필요한 행동과 결과를 이해하기 쉽게 표시, 재시작이 필요한 경우 별도 안내             |

PC 설정을 바꾸는 테스트는 임시 디렉터리나 격리 환경에서 실행합니다. 업데이트 정책이 정해지기 전에는 자동 적용을 기본 동작으로 가정하지 않습니다.
새 버전 설치와 이미 실행 중인 프로그램의 버전 전환을 구분하고, 재시작이 필요한 상태를 완료로 표시하지 않습니다.

## 커밋과 게시

커밋 전에는 변경한 파일과 diff를 확인하고 필요한 파일만 선택해 포함합니다.
커밋 메시지는 변경 내용을 짧고 구체적으로 설명합니다. 예: `docs: Shelter 유지보수 정책 명시`.

AI 도구와 작업할 때는 변경분을 먼저 검토합니다. 사용자의 명시적 커밋 지시 없이 스테이징하거나 커밋하지 않으며, 커밋에 `Co-Authored-By`를 추가하지 않습니다.

개인 Claude/Codex 디렉터리(`.claude/`, `.codex/`, `.agents/`), Claude 상태 파일(`.claude.json*`), 로컬 지침 파일(`CLAUDE.local.md`, `AGENTS.local.md`, `AGENTS.override.md`)과 `.mcp.local.json`은 `.gitignore`에서 제외합니다. 개인 경로와 인증 정보는 해당 로컬 파일에 둡니다. 공유용 프로젝트 지침인 `CLAUDE.md`, `AGENTS.md`는 Git으로 관리할 수 있습니다.

게시 전 변경 요약에 다음 내용을 기록합니다.

- 해결하려는 문제와 변경 후 동작
- 확인한 명령과 결과, 실행하지 못한 검증
- 사용자가 알아야 할 제약이나 후속 작업

문서 변경에는 링크와 미리보기 확인 결과를, 기능 변경에는 재현 가능한 검증 결과를 포함합니다.
관리자가 승인한 변경만 게시합니다. 외부 Pull Request와 Issue는 이 작업 절차에서 사용하지 않습니다.

## 배포

### 더블클릭으로 설치

사용자용 설치 단계와 macOS 보안 확인 안내는 [README 설치](./README.md#설치)를 참고하세요.

`.command` 파일 안에 설치기 전체를 포함합니다. ZIP에 실행 권한을 보존하므로 사용자가 `chmod` 명령을 입력할 필요는 없습니다. 옵션 없이 터미널에서 실행하면 설치 실패 시에도 Return 입력 전까지 결과를 유지합니다. `--dry-run` 같은 명령줄 옵션도 그대로 사용할 수 있습니다.

### 배포 파일 생성과 검증

저장소 루트에서 Shelter Lite 단일 배포 파일을 생성합니다. 패키징에는 macOS 기본 Bash와 명령줄 도구를 사용하며, 프로그램을 다운로드하거나 설치하지 않습니다.

```bash
/bin/bash installers/macos/build.sh
```

생성 결과는 다음과 같습니다.

```text
dist/
├── shelter-lite-macos.sh        # 단일 설치 파일
├── shelter-lite-macos.sh.sha256 # SHA-256 체크섬
├── shelter-lite-macos.zip       # 더블클릭용 설치 ZIP
├── shelter-lite-macos.zip.sha256 # SHA-256 체크섬
└── VERSION                     # 제품 버전의 단일 관리 지점
```

`.sh` 파일에 `install.sh`, `messages.sh`, `scripts/version.sh`, 제품 버전과 MIT 라이선스를 포함하므로, 이 파일 하나를 어떤 폴더로 옮겨도 실행할 수 있습니다. `dist/`는 Git 관리에서 제외합니다. 생성 파일을 직접 수정하지 말고 원본을 수정한 뒤 다시 생성합니다. 같은 소스에서는 같은 파일이 생성됩니다. 다른 출력 경로가 필요하면 `--output-dir "/path/with spaces"`를 사용합니다.

체크섬을 확인하고 단일 배포 파일의 코드로 격리된 테스트를 실행합니다.

```bash
(cd dist && shasum -a 256 -c shelter-lite-macos.sh.sha256)
(cd dist && shasum -a 256 -c shelter-lite-macos.zip.sha256)
/bin/bash dist/shelter-lite-macos.sh --help
SHELTER_TEST_INSTALLER="$PWD/dist/shelter-lite-macos.sh" /bin/bash installers/macos/tests/test.sh
```

사용자용 설치 단계와 macOS 보안 확인 안내는 [README 설치](./README.md#설치)를 참고하세요.

지원 조건은 기존과 같은 macOS 15 이상, 기본 Apple Silicon 환경, zsh/bash이며 실제 설치에는 인터넷 연결이 필요합니다. 설치와 `--dry-run` 시작 시 Shelter Lite ASCII 로고가 표시됩니다. 패키징과 격리 테스트는 새 Mac의 전체 설치를 검증하지 않으며, 해당 검증은 아직 진행하지 않았습니다. Homebrew 배포와 원격 단일 설치 명령은 추후 작업입니다.

### 버전 관리

공통 함수인 [scripts/version.sh](../../scripts/version.sh)는 설치기에 의존하지 않고 버전 데이터를 읽고 검증합니다. 오류 표시 방식은 이를 호출하는 쪽에서 결정합니다.

루트 [VERSION](../../VERSION)을 Shelter Lite 제품 버전의 단일 관리 지점으로 사용합니다. [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) 형식으로 앞의 `v` 없이 기록합니다. 예시는 `0.1.0`, `0.2.0-rc.1`이며, 사전 버전 식별자와 선택적인 `+build.metadata`도 SemVer 문법을 따릅니다.

현재 `0.x` 개발 단계에서는 호환되는 수정에 PATCH를, 기능 추가나 호환성 변경에 MINOR를 올립니다. 명령과 설치 동작의 안정적인 규약을 처음 제공할 때 `1.0.0`으로 전환합니다. 이후 호환되지 않는 변경은 MAJOR, 호환되는 기능 추가는 MINOR, 호환되는 수정은 PATCH를 올립니다. MAJOR나 MINOR를 올리면 하위 숫자는 0으로 초기화합니다. 릴리스 후보는 `0.2.0-rc.1`처럼 표기합니다.

1. 다음 릴리스의 `VERSION`을 수정합니다. 버전과 구현을 함께 커밋하며, 공개한 버전의 태그를 다른 코드로 옮기지 않습니다.
2. 플랫폼에 맞는 `build.sh` 또는 `build.ps1`으로 다시 생성합니다. `.sh`, `.command`와 `.ps1` 내부에 버전을 고정하고, 각 ZIP과 `dist/VERSION`에도 같은 값을 기록합니다. 원본 `VERSION`을 바꿔도 이미 만든 배포 파일은 바뀌지 않습니다.
3. `VERSION` 앞에 `v`를 붙인 태그로 GitHub 릴리스를 게시합니다. 값이 `0.2.0`이면 태그는 `v0.2.0`입니다. 릴리스 후보는 GitHub에서 사전 릴리스로 표시합니다. 태그가 다르면 workflow는 빌드와 업로드 전에 중단합니다. workflow는 지정한 버전을 검증하고 패키징하며, 버전 숫자를 자동으로 올리지는 않습니다.

```bash
/bin/bash installers/macos/install.sh --version
/bin/bash installers/macos/build.sh
/bin/bash dist/shelter-lite-macos.sh --version
cat dist/VERSION
```

`--version`은 플랫폼 검사, 다운로드와 설정 변경 없이 `Shelter Lite <version>`을 출력합니다. 제품 버전에는 `SHELTER_RELEASE_VERSION`을 사용하며, `SHELTER_VERSION`은 확인 중인 도구의 실제 버전 값으로 유지합니다. ZIP에는 확인용 `VERSION` 파일도 포함되지만 `.command` 실행에 필요한 별도 파일은 아닙니다. `dist/VERSION`은 릴리스에도 따로 첨부합니다.

### 릴리스 파일 자동 첨부

[release.yml](../../.github/workflows/release.yml)은 사전 릴리스를 포함한 GitHub 릴리스 게시 시 실행됩니다. [validate.yml](../../.github/workflows/validate.yml)을 호출해 릴리스 태그와 `VERSION` 일치 여부, 원본과 ZIP 설치기 테스트, 두 플랫폼 빌드, 체크섬과 포함된 버전을 확인합니다. macOS는 macOS 15 runner에서, Windows는 Windows 2025 runner의 기본 PowerShell 5.1에서 모의 테스트를 실행합니다. 두 작업이 모두 성공해야 플랫폼별 설치기 2개와 체크섬 2개, 공통 `VERSION`을 합한 파일 9개를 게시 작업이 업로드합니다.

검증 workflow는 `main`에 구현 변경을 push할 때도 실행되며 수동 실행도 가능합니다. 이 경우 릴리스 파일을 게시하지 않습니다.

1. workflow와 설치기 소스를 커밋하고 GitHub에 push합니다. 릴리스 태그는 이 workflow와 배포할 소스를 포함한 커밋으로 지정합니다.
2. GitHub **Releases**에서 해당 태그로 릴리스를 만들고 **Publish release**를 누릅니다. 초안 저장이나 태그 push만으로는 이 workflow가 실행되지 않습니다.
3. Actions의 **Release Shelter Lite**가 성공한 뒤 **Assets**에서 운영체제에 맞는 ZIP을 내려받습니다. 단일 `.sh`와 `.ps1`, 체크섬 4개와 공통 `VERSION`도 함께 첨부됩니다.

저장소 기본 `GITHUB_TOKEN`에 `contents: write` 권한을 사용하므로 별도 릴리스 토큰은 필요하지 않습니다. 테스트나 빌드에 실패하면 업로드를 중단합니다. 문제를 해결한 뒤 Actions에서 작업을 재실행할 수 있으며, 같은 이름의 첨부 파일은 교체합니다. 기존 릴리스에 파일을 첨부하고 격리된 테스트를 실행하는 방식이므로, 새 Mac이나 Windows PC의 전체 설치 검증을 대신하지는 않습니다.

Shelter 자체를 업데이트하는 절차와 Shelter가 사용자 PC의 소프트웨어를 업데이트하는 동작을 구분합니다.
### 릴리스 노트

릴리스 노트는 GitHub 릴리스 본문에만 작성하고, 저장소에는 별도 노트 파일을 두지 않습니다. 설치 프로그램 메시지와 같이 영어로 작성합니다. 맨 위에는 가운데 정렬한 제목과 한 문장 소개를 둡니다. **New** 아래에는 추가된 기능만 플랫폼별로 적고, 해당 릴리스에서 변경한 플랫폼에 맞춰 **macOS**와 **Windows** 섹션을 둡니다. 마지막에는 설치 파일마다 플랫폼, 요구 사항과 체크섬 링크를 적은 **Download** 표를 둡니다. 파일 링크는 workflow가 업로드를 마친 뒤 동작합니다.

```markdown
<div align="center">

# `shelter-lite@v<version>` is here!

<one sentence about this release>

</div>

## New

### macOS

- <added feature>

### Windows

- <added feature>

## Download Shelter Lite v<version>

| File | Platform | Requirements | Checksum |
| --- | --- | --- | --- |
| [shelter-lite-macos.zip](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.zip) | macOS, double-click | macOS 15 or later, Apple Silicon | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.zip.sha256) |
| [shelter-lite-macos.sh](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.sh) | macOS, Terminal | macOS 15 or later, Apple Silicon | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-macos.sh.sha256) |
| [shelter-lite-windows.zip](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.zip) | Windows, double-click | Windows 11 x64 | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.zip.sha256) |
| [shelter-lite-windows.ps1](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.ps1) | Windows, PowerShell | Windows 11 x64, Windows PowerShell 5.1 | [sha256](https://github.com/4BFC/shelter/releases/download/v<version>/shelter-lite-windows.ps1.sha256) |

Installation steps: [README](https://github.com/4BFC/shelter#install)
```
