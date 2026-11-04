```text
  ____  _          _ _
 / ___|| |__   ___| | |_ ___ _ __
 \___ \| '_ \ / _ \ | __/ _ \ '__|
  ___) | | | |  __/ | ||  __/ |
 |____/|_| |_|\___|_|\__\___|_|
```

# Shelter

Shelter sets up development tools on your Mac and checks that they run. Working tools are preserved; missing components are installed.

[![Release](https://img.shields.io/github/v/release/4BFC/shelter?include_prereleases&style=flat-square)](https://github.com/4BFC/shelter/releases)
![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white)
![Apple Silicon](https://img.shields.io/badge/Apple_Silicon-M_series-000000?style=flat-square&logo=apple&logoColor=white)
![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)

[English](README.md) · [한국어](language/ko/README.md) · [日本語](language/jp/README.md)

<!-- Add a verified terminal screenshot here when available. -->

## Contents

- [Specifications](#specifications)
- [Install](#install)
- [Usage](#usage)
- [Contribution policy](#contribution-policy)
- [License](#license)

## Specifications

| Component | Technology | Details |
| --- | --- | --- |
| Operating system | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Apple Silicon, zsh/bash |
| Installer | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | Runs with the Bash included in macOS |
| Package management | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | Installs development tools |
| CLI | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | Under consideration; version undecided |
| CLI development tools | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | Under consideration; versions undecided |

Installation policies and technical details: [technical specification](docs/specification.md).

## Install

### Requirements

- macOS 15 or later on Apple Silicon (M-series chips), using a native terminal environment. Intel Macs, Rosetta, and Windows are not supported.
- An internet connection and a macOS administrator account for Homebrew authentication when requested.
- zsh or bash for shell configuration. Homebrew, Node.js, and Python do not need to be installed beforehand. Run Shelter as your normal user, without `sudo`.

### Download and run

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

## Usage

### Read the result

Messages and logs are in English.

- `Installation complete`: the tools are ready. Open a new terminal and restart running editors to activate any new executable paths.
- `Installation failed`: setup stopped. Check the error shown in the terminal.
- `warning`: read the accompanying text for pending restarts or changes retained after failure.

<details>
<summary>After installation</summary>

Open Ghostty from Applications, or run `open -a Ghostty` in Terminal. Shelter does not change Ghostty's settings, fonts, or the default terminal.

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

### Preview and check

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

## Contribution policy

Shelter currently does not accept external pull requests or issues; both features are disabled. Development and releases are managed by the maintainer. Use, modification, and redistribution of the software are governed by the [MIT license](./LICENSE).

## License

[MIT](./LICENSE) © 2026 poby · [@4BFC](https://github.com/4BFC)
