# Shelter technical specification

[English](./specification.md) · [한국어](./specification.ko.md) · [日本語](./specification.jp.md)

[README](../README.md)

## Product Components

The **website** is where users will find security information and guidance.
**Information collection** provides the foundation for tracking official security advisories and release information.
The **CLI** connects that information to the state of the user's computer.

| Component | Planned role | Information provided to users |
| --- | --- | --- |
| Website | Collect and explain security issues and updates | Issue details, affected versions, actions to take, and sources |
| Information collection | Track security advisories and update changes | Original sources, publication dates, and last checked dates |
| CLI | Check installed tools, send relevant notifications, apply updates, and verify results | Current status, required changes, and results |

The goal is continuous tracking so security issues can be identified promptly. Collection intervals and notification latency have not been decided.
Integrated installation and management of tools such as Codex and Claude Code may be considered in later expansions.

**Shelter Lite** is an initial setup that uses a shell installer to prepare and verify the entire fixed specification. It does not allow individual tools to be selected or excluded.
The **full version** will be a CLI that continues to provide status checks, security notifications, and updates after installation.
Installation scripts are managed by operating system in `installers/macos/` and `installers/windows/`. The full CLI implementation is separate from the installer; if Python is chosen, it will be implemented in `src/shelter/`.

## Lite Installation Specification

All items below are included in Lite. Homebrew is the package manager, Git is the version control tool, VS Code is the editor, and Ghostty is the terminal app for entering commands. Node.js and Python are runtimes; npm and uv manage their respective environments. GitHub CLI provides integration with GitHub.

| Order | Tool | Role | Policy for new installations |
| --- | --- | --- | --- |
| 1 | [Homebrew](https://docs.brew.sh/Installation) | Foundation for installing software | Prepare using the official installer |
| 2 | [Git](https://formulae.brew.sh/formula/git) | Track file changes | Install Homebrew's `git`; preserve a working Apple Git installation |
| 3 | [VS Code](https://formulae.brew.sh/cask/visual-studio-code) | Edit files and code | Install Homebrew's `visual-studio-code`; preserve an existing `code` command |
| 4 | [Ghostty](https://ghostty.org/docs/install/binary) | Terminal app for running shell commands | Install the version provided by Homebrew's `ghostty` cask |
| 5 | [Node.js + npm](https://formulae.brew.sh/formula/node@24) | Run JavaScript and manage packages | Install Node.js 24.x and its bundled npm through `node@24` |
| 6 | [Python + uv](https://docs.astral.sh/uv/guides/install-python/) | Run Python and manage packages and virtual environments | Install Homebrew's `uv`, then Python 3.14.x through uv |
| 7 | [GitHub CLI (`gh`)](https://formulae.brew.sh/formula/gh) | Work with GitHub repositories and pull requests | Install Homebrew's `gh`; sign in separately |

The fixed specification means a **fixed set of tools to install**. Existing versions that run successfully are preserved. The version series above apply only to new Node.js and Python installations. Patch versions are not pinned; check actual versions and paths with `--check`. GitHub Desktop is not included.

The macOS developer tools' `/usr/bin/python3` is treated separately from a user Python installation. New Python installations provide uv-managed `python3.14` without replacing the system Python or the default commands of existing version managers. VS Code is detected through its application path, so Cursor's `code` command is not mistaken for VS Code.

Checking whether a tool runs is not a security vulnerability scan or a check for the latest version. Detailed installation and rerun policies are documented in [CONTRIBUTING](../CONTRIBUTING.md#running-lite).

## Windows fixed tool set

Windows uses the following fixed equivalents. Package IDs refer to the [Microsoft WinGet manifest repository](https://github.com/microsoft/winget-pkgs/tree/master/manifests); patch versions follow the source at installation time.

| # | Tool | Role | New installation |
| --- | --- | --- | --- |
| 1 | WinGet | Package manager | Current-user Microsoft.WinGet.Client repair if missing |
| 2 | Git | Version control | WinGet Git.Git |
| 3 | VS Code | Editor | WinGet Microsoft.VisualStudioCode, user scope |
| 4 | Windows Terminal | Terminal | WinGet Microsoft.WindowsTerminal |
| 5 | Node.js + npm | JavaScript runtime | Highest available 24.x from OpenJS.NodeJS.LTS, exact version |
| 6 | Python + uv | Python runtime and environment manager | WinGet astral-sh.uv, then uv python install 3.14 |
| 7 | GitHub CLI | GitHub integration | WinGet GitHub.cli; login is manual |

Working installations are retained. New Node.js is constrained to 24.x even if the LTS package points at a newer major. Python Store aliases do not count as installations. Partial Node/npm and broken tools block setup; Python/uv can be completed separately. Missing executable directories are appended to the backed-up user PATH. Machine PATH, profiles, terminal settings, Git identity, and authentication are preserved. Both platforms use English messages and the same option names. Windows-specific behavior is implemented in [install.ps1](../installers/windows/install.ps1) and [tools.ps1](../installers/windows/tools.ps1).

## Technical Direction

**Shelter Lite 0.2.0 has separate macOS and Windows installers.** macOS targets macOS 15+ on native Apple Silicon; Windows targets Windows 11 x64 with native Windows PowerShell 5.1. See the [Windows implementation and acceptance checks](plans/windows-lite.md). Windows 10, Windows Server, ARM64, and 32-bit processes are excluded from this Windows release.
Lite uses the Bash included in macOS or Windows PowerShell included in Windows. Node.js and Python are not prerequisites. Technologies for the full CLI and website remain under consideration.

| Area | Technology under consideration | Role | Status |
| --- | --- | --- | --- |
| Supported operating system | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Lite installation and shell configuration | Apple Silicon, zsh/bash. Intel and Rosetta excluded |
| Windows | ![Windows 11 x64](https://img.shields.io/badge/Windows-11_x64-0078D4?style=flat-square) | Fixed Lite setup, WinGet, user PATH | Implemented for x64 and Windows PowerShell 5.1; clean-PC acceptance pending |
| Website and information collection | Undecided | Collect security information and provide access and user interfaces | Technology selection pending |
| CLI implementation | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | Status checks, notifications, and updates | Primary candidate; version undecided |
| CLI development tools | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | Command definitions, Python environments, and dependency management | Candidates; versions undecided |
| Shelter Lite | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | Initial installation and environment setup for the fixed specification | Implemented and checked with Bash 3.2.57 |
| macOS distribution | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | Install and update the CLI itself | Distribution candidate |

Support conditions and installation policies are implemented in [install.sh](../installers/macos/install.sh) and [tools.sh](../installers/macos/tools.sh). The minimum operating system is restricted based on the [Homebrew installation requirements](https://docs.brew.sh/Installation). Real-device checks currently cover previews on macOS 26.6.2; actual installation across the full support range has not been verified.

## Roadmap

1. **Validate the Shelter Lite:** Environment checks, fixed-specification installation, and result verification are implemented. Verify installation on a new Mac, terminal restarts, and reruns before distribution.
2. **Connect the CLI:** Connect the computer's installed software to security information from the separate website, and notify users about relevant updates.
3. **Updates and expansion:** Implement result verification and failure handling, and expand integrated tool installation.

Lite begins with initial setup; the full CLI follows in later development. Detailed feature scope and automatic update policies remain undecided.
Both versions are managed in this repository. Website code is not included here.

The security information workflow below is planned for the full CLI. It is not yet an available feature.

```text
Read security issues and update information on the website
  → Use the CLI to check software and versions on your computer
  → Receive notifications about updates relevant to your environment
  → Apply the required updates
  → Check the results and whether a restart is needed
```

Automatic update behavior, user confirmation, and notification channels will be decided during design.
Commands for the full CLI will be documented after their implemented behavior has been verified.

## Repository Structure

### Current Structure

The directories, executable code, and documentation currently present are listed below.

```text
shelter/
├── .github/
│   └── workflows/
│       ├── validate.yml # Source and ZIP checks on macOS and Windows
│       └── release.yml # Release tests, packaging, and asset upload
├── docs/
│   ├── specification.md
│   ├── specification.ko.md
│   ├── specification.jp.md
│   └── plans/
│       ├── readme-usage.md # Plan for a usage-first README
│       └── windows-lite.md # Windows implementation and acceptance
├── dist/             # Generated output, excluded from Git
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
│   ├── macos/        # macOS installer for Lite and the future full version
│   │   ├── build.sh   # Create the standalone script and double-click ZIP
│   │   ├── install.sh # Entry point, fixed specification, and installation order
│   │   ├── messages.sh # English messages, errors, colors, and output formatting
│   │   ├── tools.sh   # Tool checks, installation, and shell configuration
│   │   └── tests/
│   │       └── test.sh # Installer tests using temporary environments
│   └── windows/
│       ├── build.ps1
│       ├── install.ps1
│       ├── launch.cmd
│       ├── messages.ps1
│       ├── tools.ps1
│       └── tests/
│           └── test.ps1
├── scripts/
│   ├── version.ps1   # PowerShell SemVer reader
│   └── version.sh    # Product version format, validation, and file reading
├── language/
│   ├── ko/
│   │   ├── README.md       # Korean installation and usage
│   │   └── CONTRIBUTING.md # Korean maintainer guide for development and releases
│   └── jp/
│       ├── README.md       # Japanese installation and usage
│       └── CONTRIBUTING.md # Japanese maintainer guide for development and releases
├── README.md         # English installation and usage
├── CONTRIBUTING.md   # English maintainer guide for development and releases
├── VERSION           # Product version, source of truth
└── LICENSE           # MIT license
```

### Component Responsibilities

Windows uses [messages.ps1](../installers/windows/messages.ps1) as the native message SSOT for its installer, build, and tests. [build.ps1](../installers/windows/build.ps1) bundles the runtime, MIT license, and root `VERSION` into a standalone `.ps1`; its ZIP adds the `.cmd` launcher and `VERSION`. [version.ps1](../scripts/version.ps1) and `version.sh` implement the same product metadata contract without depending on either installer.

Windows logic and packaging have isolated tests; actual Windows 11 installation, WinGet repair, UAC, and downloaded-file launch behavior still require clean-device acceptance. The CI workflow checks PowerShell 5.1 on Windows; a Windows Server runner is used only for mocked tests, not as a supported installation target.

[messages.sh](../installers/macos/messages.sh) is the single source of truth for English guidance, warnings, errors, help, and terminal formatting shared by the installer and tests. Failure detection, stopping installation, and exit codes remain in `install.sh` and `tools.sh`.

[build.sh](../installers/macos/build.sh) bundles the runtime sources and MIT license into `dist/shelter-lite-macos.sh`. The generated file includes the same messages and installation logic; maintain the original sources and rebuild after changes. It also packages the same executable as `Shelter Lite.command` in `dist/shelter-lite-macos.zip` for opening in Terminal.

Lite starts installation of the full fixed specification in `install.sh`, which calls functions from `tools.sh`. The same entry point will also connect the full CLI's installation workflow when it becomes available. Currently, `--mode full` exits with a message that it is not yet available. Separate directories for each version or tool are not created in advance.

The planned location for the full CLI, `src/shelter/`, will be added when Python implementation begins. The structure of the website, collection service, and shared data formats will be considered after the integration scope is defined; they are not part of the current installer structure.
Split files when shared code or tool-specific logic actually grows. The release workflow validates and packages released versions; add further checks and detailed documentation as features require them.
Follow [Adding and Changing Directories in CONTRIBUTING](../CONTRIBUTING.md#adding-and-changing-directories) for when to create directories and update documentation.

## Command reference

| Option | Behavior |
| --- | --- |
| No options | Run the complete Lite initial setup |
| `--dry-run` | Show the installation plan only; no downloads or configuration changes |
| `--check` | Check whether all tools run; no downloads or configuration changes |
| `--version`, `-V` | Show the Shelter Lite product version without changing the environment |
| `--mode lite` | Same as the default |
| `--mode full` | Exit with a message that it is not yet available; do not install |
| `--color auto\|always\|never` | Automatic colors, always-on colors (default), or plain output |
| `--color` | Force colors for this run; same as `--color always` |
| `--help` | Show help |

Exit codes are `0` for success, `1` for missing tools or execution/installation errors, `2` for invalid options or unsupported environments, and `130` for Ctrl+C. Do not combine `--check` and `--dry-run`. A successful preview returns `0` even when tools are missing.

The `130` Ctrl+C code applies to macOS; Windows interruption follows the PowerShell/CMD host. Both platforms use `0`, `1`, and `2` for the cases above.
