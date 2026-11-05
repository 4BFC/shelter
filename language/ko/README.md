```text
  ____  _          _ _
 / ___|| |__   ___| | |_ ___ _ __
 \___ \| '_ \ / _ \ | __/ _ \ '__|
  ___) | | | |  __/ | ||  __/ |
 |____/|_| |_|\___|_|\__\___|_|       Hello, AI World
```

# Shelter

Shelter는 macOS와 Windows에 개발 도구를 설치하고 실행 상태를 확인합니다. 정상 작동하는 도구는 유지하고, 없는 구성 요소를 준비합니다.

[![Release](https://img.shields.io/github/v/release/4BFC/shelter?include_prereleases&style=flat-square)](https://github.com/4BFC/shelter/releases)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M_series-000000?style=flat-square&logo=apple&logoColor=white)
![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)

<div align="center">
<table align="center">
  <tr>
    <td align="center"><a href="../../README.md"><img src="https://img.shields.io/badge/English-555555?style=flat-square" alt="English"></a></td>
    <td align="center"><a href="README.md"><img src="https://img.shields.io/badge/%ED%95%9C%EA%B5%AD%EC%96%B4-0969DA?style=flat-square" alt="한국어"></a></td>
    <td align="center"><a href="../jp/README.md"><img src="https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=flat-square" alt="日本語"></a></td>
  </tr>
</table>
</div>

<!-- 검증된 터미널 실행 화면을 준비하면 이 위치에 추가합니다. -->

## 목차

- [스펙](#스펙)
- [설치](#설치)
- [사용법](#사용법)
- [기여 정책](#기여-정책)
- [라이선스](#라이선스)

## 스펙

### 지원 도구

라이트는 도구 선택 없이 아래 고정 구성을 모두 준비합니다. 버전 표기는 새 설치 기준이며, 정상 실행되는 기존 버전은 유지합니다.

| 구성 | macOS | Windows |
| --- | --- | --- |
| 패키지 관리 | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | ![WinGet](https://img.shields.io/badge/WinGet-0078D4?style=flat-square) |
| 버전 관리 | ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white) | ![Git](https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white) |
| 편집기 | ![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=flat-square) | ![VS Code](https://img.shields.io/badge/VS_Code-007ACC?style=flat-square) |
| 터미널 | ![Ghostty](https://img.shields.io/badge/Ghostty-3551F3?style=flat-square&logo=ghostty&logoColor=white) | ![Windows Terminal](https://img.shields.io/badge/Windows_Terminal-4D4D4D?style=flat-square) |
| JavaScript | ![Node.js 24.x](https://img.shields.io/badge/Node.js-24.x-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white) ![npm](https://img.shields.io/badge/npm-CB3837?style=flat-square&logo=npm&logoColor=white) | ![Node.js 24.x](https://img.shields.io/badge/Node.js-24.x-5FA04E?style=flat-square&logo=nodedotjs&logoColor=white) ![npm](https://img.shields.io/badge/npm-CB3837?style=flat-square&logo=npm&logoColor=white) |
| Python | ![Python 3.14.x](https://img.shields.io/badge/Python-3.14.x-3776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | ![Python 3.14.x](https://img.shields.io/badge/Python-3.14.x-3776AB?style=flat-square&logo=python&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) |
| GitHub 연동 | ![GitHub CLI (gh)](https://img.shields.io/badge/GitHub_CLI-gh-181717?style=flat-square&logo=github&logoColor=white) | ![GitHub CLI (gh)](https://img.shields.io/badge/GitHub_CLI-gh-181717?style=flat-square&logo=github&logoColor=white) |

### 실행 요구 사항

설치기는 아래 운영체제에 기본으로 포함된 셸에서 실행합니다.

| 구성 | 기술 | 설명 |
| --- | --- | --- |
| macOS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Apple Silicon, zsh/bash |
| macOS 설치기 | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | macOS에 포함된 Bash로 실행 |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | 기본 x64 환경 |
| Windows 설치기 | ![Windows PowerShell 5.1](https://img.shields.io/badge/Windows_PowerShell-5.1-5391FE?style=flat-square) | Windows에 포함된 Desktop 에디션으로 실행 |

설치 정책과 기술별 세부 내용은 [기술 사양](../../docs/specification.ko.md)에 정리합니다.

## 설치

### macOS 지원 조건

- macOS 15 이상, Apple Silicon(M 시리즈 칩)의 기본 터미널 환경. macOS 설치기는 Intel Mac, Rosetta와 Windows를 지원하지 않습니다.
- 인터넷 연결과 Homebrew 인증 요청에 사용할 macOS 관리자 계정.
- 셸 설정은 zsh와 bash를 지원합니다. Homebrew, Node.js와 Python을 미리 설치할 필요는 없습니다. Shelter 자체는 `sudo` 없이 일반 사용자로 실행합니다.

### macOS 내려받기와 실행

[GitHub Releases](https://github.com/4BFC/shelter/releases)에서 설치 파일을 내려받습니다. 아래는 **Assets**에 `shelter-lite-macos.zip`이 게시된 경우의 절차입니다. 아직 파일이 없다면 [소스 빌드 안내](./CONTRIBUTING.md#배포)를 참고하세요.

1. 릴리스의 **Assets**에서 `shelter-lite-macos.zip`을 내려받습니다. GitHub의 소스 코드 ZIP과는 다른 파일입니다.
2. ZIP을 더블클릭해 풀고, `Shelter Lite.command`를 더블클릭합니다. 터미널이 열리며 설치를 시작합니다.
3. Homebrew의 진행 확인이나 관리자 비밀번호 요청이 나오면 응답합니다. 비밀번호를 입력해도 화면에 글자가 표시되지 않을 수 있습니다. Mac 로그인 비밀번호를 입력하고 Return을 누르세요.
4. 마지막 결과를 읽고 Return을 눌러 마칩니다. [사용법](#사용법)에 따라 새 환경을 적용하고 확인합니다.

설치 파일은 서명되지 않은 스크립트입니다. macOS가 실행을 막으면 내려받은 출처를 확인하고 [Apple의 보안 안내](https://support.apple.com/en-us/102445)를 참고하세요. 확인되지 않은 개발자 경고의 경우, Apple은 파일을 신뢰할 때 실행 시도 후 **시스템 설정 → 개인정보 보호 및 보안 → 확인 없이 열기**로 허용하는 절차를 안내합니다.

<details>
<summary>선택: 내려받은 파일 확인</summary>

체크섬은 내려받은 파일이 게시된 파일과 같은지 확인하는 값입니다. `shelter-lite-macos.zip.sha256`도 ZIP과 같은 폴더에 내려받으세요. 두 파일이 다운로드 폴더에 있다면 터미널에서 실행합니다.

```bash
cd ~/Downloads
shasum -a 256 -c shelter-lite-macos.zip.sha256
```

`shelter-lite-macos.zip: OK`가 나올 때만 진행합니다. 값이 다르면 설치기를 실행하기 전에 두 파일을 다시 내려받으세요.

</details>

### Windows 내려받기와 실행

Windows 지원은 소스 버전 `0.2.0`에 구현되어 있습니다. 저장소 변경과 CI 빌드는 릴리스 게시보다 앞설 수 있습니다. **Assets**에 `shelter-lite-windows.zip`이 있는 릴리스에서만 내려받으세요. 배포 파일은 릴리스 게시와 workflow 성공 후 제공됩니다.

- Windows 11 x64, 기본 64비트 Windows PowerShell 5.1을 사용합니다. Windows 10, Windows Server, ARM64와 32비트 프로세스는 지원하지 않습니다.
- **관리자 권한으로 실행**하지 말고 일반 계정으로 시작합니다. 인터넷 연결이 필요하며, 개별 패키지의 UAC 인증 요청에 응답합니다. 조직 정책에 따라 설치가 제한될 수 있습니다.
- 고정 구성은 WinGet, Git, VS Code, Windows Terminal, Node.js 24/npm, Python 3.14/uv, GitHub CLI입니다. 정상 실행되는 기존 버전은 유지합니다. WinGet이 없으면 Microsoft의 현재 사용자용 복구 모듈로 준비합니다.

실행기는 기본 Windows PowerShell 5.1을 사용하며, PowerShell 7은 설치 지원 대상이 아닙니다.

1. `shelter-lite-windows.zip`의 **모든 파일**을 같은 폴더에 풉니다.
2. `Shelter Lite.cmd`를 더블클릭합니다. `shelter-lite-windows.ps1`을 같은 폴더에 두세요. 설치 과정에서 고정 도구의 WinGet 소스와 패키지 약관에 동의합니다.
3. 결과를 읽고 아무 키나 눌러 창을 닫습니다. 이후 터미널과 편집기를 다시 여세요.

서명되지 않은 스크립트입니다. 실행기는 해당 프로세스에서만 실행 정책을 지정하며, 저장된 정책이나 조직 정책을 변경하지 않습니다. Windows 보안 경고가 표시될 수 있습니다. 깨끗한 Windows 11 PC에서 전체 설치는 아직 검증하지 않았습니다.

ZIP을 확인하려면 `.sha256` 파일도 같은 폴더에 내려받고, 그 위치에서 PowerShell로 다음을 실행하세요. 결과가 `True`일 때만 진행합니다.

```powershell
$expected = ((Get-Content .\shelter-lite-windows.zip.sha256 -Raw) -split ' ')[0]
(Get-FileHash .\shelter-lite-windows.zip -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $expected
```

## 사용법

### 결과 읽기

메시지와 로그는 영어로 표시합니다.

- `Installation complete`(설치 완료): 도구가 준비되었습니다. 새 터미널을 열고 실행 중인 편집기를 다시 시작해 추가된 실행 경로를 적용하세요.
- `Installation failed`(설치 실패): 설치가 중단되었습니다. 터미널에 표시된 오류를 확인하세요.
- `warning`(경고): 재시작이 필요하거나 실패 후 변경 사항이 남았다는 안내를 확인하세요.

<details>
<summary>설치 후 할 일</summary>

macOS에서는 응용 프로그램 폴더에서 Ghostty를 열거나 터미널에서 `open -a Ghostty`를 실행합니다. Windows에서는 시작 메뉴에서 Windows Terminal을 엽니다. 터미널 설정, 글꼴과 기본 터미널은 변경하지 않습니다.

Git을 사용한다면 커밋에 기록할 사용자 정보를 직접 설정하세요. 예시의 이름과 이메일을 본인 정보로 바꿔 실행합니다. 이 전역 설정은 현재 사용자 계정에 적용됩니다. 이미 올바르게 설정했다면 유지하세요.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

GitHub CLI를 GitHub 계정과 연결하려면 다음 명령을 실행하고 안내를 따릅니다.

```bash
gh auth login
```

</details>

### macOS 미리보기와 상태 확인

압축을 푼 `Shelter Lite.command`를 보관하세요. 새 터미널에서 해당 파일이 있는 폴더로 이동합니다. 아래 예시는 다운로드 폴더 바로 아래에 파일이 있다고 가정합니다. 다른 곳에 풀었다면 경로를 바꾸세요. 각 명령은 독립적이며, 도구 설치나 설정 변경을 하지 않습니다.

```bash
cd ~/Downloads
/bin/bash "Shelter Lite.command" --dry-run
/bin/bash "Shelter Lite.command" --check
echo $?
/bin/bash "Shelter Lite.command" --version
/bin/bash "Shelter Lite.command" --help
```

`--dry-run`은 없는 도구와 변경 예정 내용을 미리 보여줍니다. `--check`의 모든 항목이 `Installed`(설치됨)이고 바로 뒤의 `echo $?`가 `0`이면 전체 도구를 실행할 수 있습니다. 보안 취약점이나 최신 버전 여부를 검사하는 기능은 아닙니다.

전체 옵션은 `--help`로 확인할 수 있습니다.

단일 파일을 내려받았다면 해당 폴더에서 `/bin/bash shelter-lite-macos.sh`에 같은 옵션을 붙여 실행합니다. 두 파일 모두 옵션 없이 실행하면 설치를 시작합니다.

### Windows 미리보기와 확인

ZIP을 푼 폴더에서 PowerShell을 여세요. 다음 명령은 설치나 설정 변경을 하지 않습니다.

```powershell
& '.\Shelter Lite.cmd' --dry-run
& '.\Shelter Lite.cmd' --check
$LASTEXITCODE
& '.\Shelter Lite.cmd' --version
& '.\Shelter Lite.cmd' --help
```

`--check` 직후 `$LASTEXITCODE`를 확인하세요. `0`은 모든 도구가 준비됐음을, `1`은 확인이 필요함을 뜻합니다. 설치 시 사용자 PATH를 백업하고 필요한 실행 경로만 뒤에 추가합니다. PowerShell 프로필, 시스템 PATH, Git 사용자 정보와 GitHub 로그인은 유지합니다. 로그와 PATH 백업은 `%LOCALAPPDATA%\Shelter\logs`에 저장합니다. 새 Python은 `python3.14`로 실행하며, 기존 `python` 명령과 Store 별칭의 우선순위는 유지합니다.

## 기여 정책

현재 외부 Pull Request와 Issue를 받지 않으며, 두 기능은 비활성화되어 있습니다. 개발과 배포는 관리자가 담당합니다. 소프트웨어의 사용, 수정과 재배포에는 [MIT 라이선스](../../LICENSE)가 적용됩니다.

## 라이선스

[MIT](../../LICENSE) © 2026 poby · [@4BFC](https://github.com/4BFC)
