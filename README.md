```text
  ____  _          _ _
 / ___|| |__   ___| | |_ ___ _ __
 \___ \| '_ \ / _ \ | __/ _ \ '__|
  ___) | | | |  __/ | ||  __/ |
 |____/|_| |_|\___|_|\__\___|_|       Hello, AI World
```

# Shelter

Shelter sets up development tools on macOS and Windows and checks that they run. Working tools are preserved; missing components are installed.

[![Release](https://img.shields.io/github/v/release/4BFC/shelter?include_prereleases&style=flat-square)](https://github.com/4BFC/shelter/releases)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M_series-000000?style=flat-square&logo=apple&logoColor=white)
![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)

<div align="center">
<table align="center">
  <tr>
    <td align="center"><a href="README.md"><img src="https://img.shields.io/badge/English-0969DA?style=flat-square" alt="English"></a></td>
    <td align="center"><a href="language/ko/README.md"><img src="https://img.shields.io/badge/%ED%95%9C%EA%B5%AD%EC%96%B4-555555?style=flat-square" alt="한국어"></a></td>
    <td align="center"><a href="language/jp/README.md"><img src="https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=flat-square" alt="日本語"></a></td>
  </tr>
</table>
</div>

<!-- Add a verified terminal screenshot here when available. -->

## Contents

- [Specifications](#specifications)
- [Install](#install)
- [Usage](#usage)
- [Contribution policy](#contribution-policy)
- [License](#license)

## Specifications

### Available installers

Shelter Lite ships as the following script installers. Download the file for your platform from the latest published release.

| Platform | Installer | How to run |
| --- | --- | --- |
| macOS | [shelter-lite-macos.zip](https://github.com/4BFC/shelter/releases/latest/download/shelter-lite-macos.zip) | Extract and double-click `Shelter Lite.command` |
| macOS | [shelter-lite-macos.sh](https://github.com/4BFC/shelter/releases/latest/download/shelter-lite-macos.sh) | Run with macOS Bash |
| Windows | [shelter-lite-windows.zip](https://github.com/4BFC/shelter/releases/latest/download/shelter-lite-windows.zip) | Extract all files and double-click `Shelter Lite.cmd` |
| Windows | [shelter-lite-windows.ps1](https://github.com/4BFC/shelter/releases/latest/download/shelter-lite-windows.ps1) | Run with Windows PowerShell 5.1 |

Each installer has a matching `.sha256` checksum file, and both platforms share the `VERSION` asset. A separate `shelter-lite` command and the full Shelter CLI are not yet available.

### Installed tools

Lite prepares this entire fixed set without tool selection. The version targets below apply to new installations; working existing versions are preserved.

| Component | macOS | Windows |
| --- | --- | --- |
| Package manager | Homebrew | WinGet |
| Version control | Git | Git |
| Editor | VS Code | VS Code |
| Terminal | Ghostty | Windows Terminal |
| JavaScript | Node.js 24.x + npm | Node.js 24.x + npm |
| Python | Python 3.14.x + uv | Python 3.14.x + uv |
| GitHub integration | GitHub CLI (`gh`) | GitHub CLI (`gh`) |

### Supported environment

| Component | Technology | Details |
| --- | --- | --- |
| macOS | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Apple Silicon, zsh/bash |
| macOS installer | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | Runs with the Bash included in macOS |
| macOS package manager | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | Installs development tools |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | Native x64 |
| Windows installer | ![Windows PowerShell 5.1](https://img.shields.io/badge/Windows_PowerShell-5.1-5391FE?style=flat-square) | Uses the Windows built-in Desktop edition |
| Windows package manager | ![WinGet](https://img.shields.io/badge/WinGet-0078D4?style=flat-square) | Prepares missing WinGet before installing tools |

Installation policies and technical details: [technical specification](docs/specification.md).

## Install

### macOS requirements

- macOS 15 or later on Apple Silicon (M-series chips), using a native terminal environment. The macOS installer does not support Intel Macs, Rosetta, or Windows.
- An internet connection and a macOS administrator account for Homebrew authentication when requested.
- zsh or bash for shell configuration. Homebrew, Node.js, and Python do not need to be installed beforehand. Run Shelter as your normal user, without `sudo`.

### macOS download and run

Download the installer from [GitHub Releases](https://github.com/4BFC/shelter/releases). The steps below apply when `shelter-lite-macos.zip` is available under **Assets**. If it has not been published yet, use the [source build instructions](./CONTRIBUTING.md#distribution).

1. Under the release's **Assets**, download `shelter-lite-macos.zip` (not GitHub's source-code ZIP).
2. Double-click the ZIP to extract it, then double-click `Shelter Lite.command`. Terminal opens and starts setup.
3. Respond to Homebrew's confirmation and administrator password prompts if shown. Password characters may not appear as you type; enter your Mac login password and press Return.
4. Read the final result, then press Return to finish. Follow [Usage](#usage) to activate and check the tools.

The installer is an unsigned script. If macOS blocks it, confirm the download source and consult [Apple's security guidance](https://support.apple.com/en-us/102445). For an unidentified-developer warning, Apple describes **System Settings → Privacy & Security → Open Anyway** after an opening attempt, when you trust the file.

<details>
<summary>Optional: verify the download</summary>

A checksum checks whether the download matches the published file. Download `shelter-lite-macos.zip.sha256` into the same folder as the ZIP. If both are in Downloads, open Terminal and run:

```bash
cd ~/Downloads
shasum -a 256 -c shelter-lite-macos.zip.sha256
```

Continue only if the result is `shelter-lite-macos.zip: OK`. On a mismatch, download both files again before running the installer.

</details>

### Windows download and run

Windows support is implemented in the `0.2.0` source version. Repository changes and CI builds can precede a published release. Download `shelter-lite-windows.zip` only from a release that lists it under **Assets**; files become available after publication and a successful release workflow.

- Windows 11 x64 with native Windows PowerShell 5.1. Windows 10, Windows Server, ARM64, and 32-bit processes are not supported.
- Use your regular account, without **Run as administrator**. Internet access is required; approve individual package UAC prompts when requested. Organization policies may prevent installation.
- The fixed set includes WinGet, Git, VS Code, Windows Terminal, Node.js 24/npm, Python 3.14/uv, and GitHub CLI. Working existing versions are preserved. Missing WinGet is prepared through Microsoft's current-user repair module.

The launcher selects built-in Windows PowerShell 5.1; PowerShell 7 is not an installation target.

1. Extract **all** files from `shelter-lite-windows.zip` into one folder.
2. Double-click `Shelter Lite.cmd`. Keep `shelter-lite-windows.ps1` beside it. Setup accepts the WinGet source and package agreements for the fixed tools.
3. Read the result, then press a key to close the window. Reopen your terminal and editor afterward.

These scripts are unsigned. The launcher uses a process-only execution-policy setting; it does not change the saved policy or override organization policies. Windows may display security warnings. Full installation on a clean Windows 11 computer has not yet been verified.

To verify the ZIP, download its `.sha256` file into the same folder and run this in PowerShell there. Continue only if the result is `True`.

```powershell
$expected = ((Get-Content .\shelter-lite-windows.zip.sha256 -Raw) -split ' ')[0]
(Get-FileHash .\shelter-lite-windows.zip -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $expected
```

## Usage

### Read the result

Messages and logs are in English.

- `Installation complete`: the tools are ready. Open a new terminal and restart running editors to activate any new executable paths.
- `Installation failed`: setup stopped. Check the error shown in the terminal.
- `warning`: read the accompanying text for pending restarts or changes retained after failure.

<details>
<summary>After installation</summary>

On macOS, open Ghostty from Applications, or run `open -a Ghostty` in Terminal. On Windows, open Windows Terminal from the Start menu. Shelter does not change terminal settings, fonts, or the default terminal.

If you will use Git, set your commit identity yourself. Replace the example name and email with your own; these global settings apply to your user account. If already configured correctly, keep them.

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

To connect GitHub CLI to your GitHub account, run the following and follow its prompts:

```bash
gh auth login
```

</details>

### macOS preview and check

Keep the extracted `Shelter Lite.command`. In a new terminal, change to the folder containing it. The examples assume it is directly in Downloads; adjust the path if you extracted it elsewhere. Each command below is separate and does not install tools or change configuration.

```bash
cd ~/Downloads
/bin/bash "Shelter Lite.command" --dry-run
/bin/bash "Shelter Lite.command" --check
echo $?
/bin/bash "Shelter Lite.command" --version
/bin/bash "Shelter Lite.command" --help
```

`--dry-run` previews missing tools and planned changes. If `--check` shows every item as `Installed` and `echo $?` immediately afterward prints `0`, all tools can run. This checks execution, not security vulnerabilities or whether versions are the latest.

See `--help` for all options.

For the standalone download, use `/bin/bash shelter-lite-macos.sh` in its folder with the same options. With no options, either file starts installation.

### Windows preview and check

Open PowerShell in the extracted ZIP's folder. These commands perform no installations or configuration changes:

```powershell
& '.\Shelter Lite.cmd' --dry-run
& '.\Shelter Lite.cmd' --check
$LASTEXITCODE
& '.\Shelter Lite.cmd' --version
& '.\Shelter Lite.cmd' --help
```

Read `$LASTEXITCODE` immediately after `--check`: `0` means every tool is ready; `1` means something needs attention. Setup appends missing executable directories to your user PATH after saving a backup. PowerShell profiles, machine PATH, Git identity, and GitHub login are preserved. Logs and PATH backups are under `%LOCALAPPDATA%\Shelter\logs`. New Python installs provide `python3.14`; existing `python` commands and Store aliases retain their priority.

## Contribution policy

Shelter currently does not accept external pull requests or issues; both features are disabled. Development and releases are managed by the maintainer. Use, modification, and redistribution of the software are governed by the [MIT license](./LICENSE).

## License

[MIT](./LICENSE) © 2026 poby · [@4BFC](https://github.com/4BFC)
