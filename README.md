# Shelter _(shelter)_

[![README style: standard](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)
[![Status: prototype](https://img.shields.io/badge/status-prototype-D99A4E?style=flat-square)](#roadmap)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](./LICENSE)

A shelter for your environment. From tracking security threats to notifications and updates.

| English | 한국어 | 日本語 |
| --- | --- | --- |
| **Current** | [한국어](./language/ko/README.md) | [日本語](./language/jp/README.md) |

Shelter aims to help users identify and apply the updates their environment needs without having to follow security news themselves.
Security issues and update information will be provided through a separate website, with a CLI connecting that information to status checks, notifications, and updates on the user's computer.

**The Shelter Lite installer is currently in its first implementation stage.** It provides a shell installer that prepares a fixed set of development tools on macOS. Tests in temporary environments and installation previews on a real Mac have been verified. Full installation on a new Mac and implementation of the full CLI remain to be completed.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
- [Product Components](#product-components)
- [Lite Installation Specification](#lite-installation-specification)
- [Technical Direction](#technical-direction)
- [Roadmap](#roadmap)
- [Repository Structure](#repository-structure)
- [Maintainer](#maintainer)
- [Contributing](#contributing)
- [License](#license)

## Background

When a new security issue is announced, users may struggle to find the advisory, determine whether their installed version is affected, and work out how to update it.
Different installation paths and update methods across tools make this harder to manage.

Shelter aims to connect these steps: **track → compare with your environment → notify → update → verify**.
Its primary audience is people unfamiliar with security advisories or development tools. It should clearly explain what the problem is, whether it affects them, and what to do next.

## Install

Run Shelter Lite by extracting `shelter-lite-macos.zip` and double-clicking `Shelter Lite.command`, or by running the standalone `.sh` file. It targets **macOS 15 or later in a native Apple Silicon terminal environment** and supports zsh and bash configuration.
Local script and double-click ZIP packaging are available. See [Distribution in CONTRIBUTING](./CONTRIBUTING.md#distribution) for building, checking, and running the file. Publishing a GitHub Release triggers automated tests, packaging, and attachment of the installers. A Homebrew Tap is not yet configured.

Current development version: **0.1.0**. The product version is managed in [VERSION](./VERSION). Built installers embed that value; version inspection and release rules are documented in [CONTRIBUTING](./CONTRIBUTING.md#versioning). The shared reader in [scripts/version.sh](./scripts/version.sh) validates the version for the installer, build, and release workflow without performing installation.

See [Development Setup in CONTRIBUTING](./CONTRIBUTING.md#development-setup) for obtaining the repository and getting started, and [Running Lite](./CONTRIBUTING.md#running-lite) for settings changed during installation.

## Usage

Lite prepares the initial environment in this order: **Homebrew → Git → VS Code → Ghostty → Node.js/npm → Python/uv → GitHub CLI**. There is no tool selection menu. Existing tools that run successfully are preserved, and missing components are installed. The default output ends with **installation complete or installation failed**, a short explanation, and warnings only when relevant. The wording distinguishes these states even when colors are disabled. Details are written to the installation log; use `--check` to inspect current versions and executable paths.

See [Message Previews](./CONTRIBUTING.md#message-previews) for each state's wording and color, and [Installation Workflow Tests](./CONTRIBUTING.md#installation-workflow-tests) for a simulated run of the actual installation process.

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

The **Shelter Lite** is an initial setup that uses a shell installer to prepare and verify the entire fixed specification. It does not allow individual tools to be selected or excluded.
The **full version** will be a CLI that continues to provide status checks, security notifications, and updates after installation.
Installation scripts for both versions are managed in `installers/macos/`. The full CLI implementation is separate from the installer; if Python is chosen, it will be implemented in `src/shelter/`.

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

Checking whether a tool runs is not a security vulnerability scan or a check for the latest version. Detailed installation and rerun policies are documented in [CONTRIBUTING](./CONTRIBUTING.md#running-lite).

## Technical Direction

**The implemented target operating system for the installer is macOS.** Windows support is in preparation only; see the [Windows plan](./docs/plans/windows-lite.md). Windows installation, configuration, packaging, and release jobs have not been implemented.
Lite runs with the Bash included in macOS; Node.js and Python do not need to be installed beforehand. Technologies for the full CLI and website are still under consideration.

| Area | Technology under consideration | Role | Status |
| --- | --- | --- | --- |
| Initial target operating system | ![macOS 15+](https://img.shields.io/badge/macOS-15%2B-000000?style=flat-square&logo=apple&logoColor=white) | Lite installation and shell configuration | Apple Silicon, zsh/bash. Intel, Rosetta, and Windows excluded |
| Windows preparation | Windows 11, built-in PowerShell, WinGet (candidates) | Define Windows initial setup and distribution | Planning only; no Windows installer or release assets |
| Website and information collection | Undecided | Collect security information and provide access and user interfaces | Technology selection pending |
| CLI implementation | ![Python](https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white) | Status checks, notifications, and updates | Primary candidate; version undecided |
| CLI development tools | ![Typer](https://img.shields.io/badge/Typer-009688?style=flat-square&logo=typer&logoColor=white) ![uv](https://img.shields.io/badge/uv-DE5FE9?style=flat-square&logo=uv&logoColor=white) | Command definitions, Python environments, and dependency management | Candidates; versions undecided |
| Shelter Lite | ![Bash 3.2.57](https://img.shields.io/badge/Bash-3.2.57-4EAA25?style=flat-square&logo=gnubash&logoColor=white) | Initial installation and environment setup for the fixed specification | Implemented and checked with Bash 3.2.57 |
| macOS distribution | ![Homebrew](https://img.shields.io/badge/Homebrew-FBB040?style=flat-square&logo=homebrew&logoColor=black) | Install and update the CLI itself | Distribution candidate |

Support conditions and installation policies are implemented in [install.sh](./installers/macos/install.sh) and [tools.sh](./installers/macos/tools.sh). The minimum operating system is restricted based on the [Homebrew installation requirements](https://docs.brew.sh/Installation). Real-device checks currently cover previews on macOS 26.6.2; actual installation across the full support range has not been verified.

## Roadmap

1. **Validate the Shelter Lite:** Environment checks, fixed-specification installation, and result verification are implemented. Verify installation on a new Mac, terminal restarts, and reruns before distribution.
2. **Connect the CLI:** Connect the computer's installed software to security information from the separate website, and notify users about relevant updates.
3. **Updates and expansion:** Implement result verification and failure handling, and expand integrated tool installation.

Lite begins with initial setup; the full CLI follows in later development. Detailed feature scope and automatic update policies remain undecided.
Both versions are managed in this repository. Website code is not included here.

## Repository Structure

### Current Structure

The directories, executable code, and documentation currently present are listed below.

```text
shelter/
├── .github/
│   └── workflows/
│       └── release.yml # Release tests, packaging, and asset upload
├── docs/
│   └── plans/
│       └── windows-lite.md # Windows preparation notes
├── dist/             # Generated output, excluded from Git
│   ├── shelter-lite-macos.sh
│   ├── shelter-lite-macos.sh.sha256
│   ├── shelter-lite-macos.zip
│   ├── shelter-lite-macos.zip.sha256
│   └── VERSION
├── installers/
│   └── macos/        # macOS installer for Lite and the future full version
│       ├── build.sh   # Create the standalone script and double-click ZIP
│       ├── install.sh # Entry point, fixed specification, and installation order
│       ├── messages.sh # English messages, errors, colors, and output formatting
│       ├── tools.sh   # Tool checks, installation, and shell configuration
│       └── tests/
│           └── test.sh # Installer tests using temporary environments
├── scripts/
│   └── version.sh    # Product version format, validation, and file reading
├── language/
│   ├── ko/
│   │   ├── README.md       # Korean introduction, components, and direction
│   │   └── CONTRIBUTING.md # Korean setup, validation, and contribution guide
│   └── jp/
│       ├── README.md       # Japanese introduction, components, and direction
│       └── CONTRIBUTING.md # Japanese setup, validation, and contribution guide
├── README.md         # English introduction, components, and direction
├── CONTRIBUTING.md   # English setup, validation, and contribution guide
├── VERSION           # Product version, source of truth
└── LICENSE           # MIT license
```

### Component Responsibilities

[messages.sh](./installers/macos/messages.sh) is the single source of truth for English guidance, warnings, errors, help, and terminal formatting shared by the installer and tests. Failure detection, stopping installation, and exit codes remain in `install.sh` and `tools.sh`.

[build.sh](./installers/macos/build.sh) bundles the runtime sources and MIT license into `dist/shelter-lite-macos.sh`. The generated file includes the same messages and installation logic; maintain the original sources and rebuild after changes. It also packages the same executable as `Shelter Lite.command` in `dist/shelter-lite-macos.zip` for opening in Terminal.

Lite starts installation of the full fixed specification in `install.sh`, which calls functions from `tools.sh`. The same entry point will also connect the full CLI's installation workflow when it becomes available. Currently, `--mode full` exits with a message that it is not yet available. Separate directories for each version or tool are not created in advance.

The planned location for the full CLI, `src/shelter/`, will be added when Python implementation begins. The structure of the website, collection service, and shared data formats will be considered after the integration scope is defined; they are not part of the current installer structure.
Split files when shared code or tool-specific logic actually grows. The release workflow validates and packages released versions; add further checks and detailed documentation as features require them.
Follow [Adding and Changing Directories in CONTRIBUTING](./CONTRIBUTING.md#adding-and-changing-directories) for when to create directories and update documentation.

## Maintainer

[@4BFC](https://github.com/4BFC)

## Contributing

Documentation improvements, feature suggestions, and pull requests are welcome.
Use [Issues](https://github.com/4BFC/shelter/issues) for questions and suggestions. Discuss major features and technology choices before implementation.

See [CONTRIBUTING](./CONTRIBUTING.md) for setup, validation, and submission requirements.

## License

[MIT](./LICENSE) © 2026 poby
