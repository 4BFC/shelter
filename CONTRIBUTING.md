# Development and Maintenance

<div align="center">
<table align="center">
  <tr>
    <td align="center"><a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/English-0969DA?style=flat-square" alt="English"></a></td>
    <td align="center"><a href="language/ko/CONTRIBUTING.md"><img src="https://img.shields.io/badge/%ED%95%9C%EA%B5%AD%EC%96%B4-555555?style=flat-square" alt="한국어"></a></td>
    <td align="center"><a href="language/jp/CONTRIBUTING.md"><img src="https://img.shields.io/badge/%E6%97%A5%E6%9C%AC%E8%AA%9E-555555?style=flat-square" alt="日本語"></a></td>
  </tr>
</table>
</div>

This guide covers development, documentation, validation, and releases for Shelter's maintainer.
See the [README](./README.md) for the project's purpose, components, and technical direction.

Shelter Lite for macOS and Windows, isolated tests, script and double-click ZIP packaging, and automated release builds are available. The full CLI is not yet ready.

## Table of Contents

- [Contribution Policy](#contribution-policy)
- [Development Setup](#development-setup)
- [Running Lite](#running-lite)
- [Windows Lite](#windows-lite)
- [Adding and Changing Directories](#adding-and-changing-directories)
- [Workflow](#workflow)
- [Writing Documentation](#writing-documentation)
- [Implementation and Validation](#implementation-and-validation)
- [Commits and Publishing](#commits-and-publishing)
- [Distribution](#distribution)

## Contribution Policy

Shelter currently does not accept external pull requests or issues; both features are disabled. Development decisions and releases are managed by the maintainer, who holds write access to the repository.

The software remains available under the [MIT license](./LICENSE). This contribution policy does not restrict the use, modification, or redistribution permitted by that license.

Before implementation, the maintainer defines the scope of technology choices, additional operating systems, and major features, and records:

- Which users encounter the problem and in what situation
- The expected behavior and how it differs from the current behavior
- Related advisories, reproduction steps, or references

Distinguish security advisories from defects in Shelter itself. Remove tokens, credentials, and personal paths from reproduction material before sharing it.

## Development Setup

### Getting the Repository

If Git is available, clone the repository and enter its root directory as follows. Skip this step if you already have a copy.

```bash
git clone https://github.com/4BFC/shelter.git
cd shelter
git status --short
```

Without Git on macOS or Windows, use **Code → Download ZIP** on GitHub, extract the full source, and enter its root directory. Keep the root `VERSION`, `scripts/`, and the relevant `installers/macos/` or `installers/windows/` directory together.

Each standalone installer embeds its runtime modules and product version; see [Distribution](#distribution) for packaging and [Windows Lite](#windows-lite) for Windows commands.

### Runtime Environment

The macOS installation target is **macOS 15 or later, Apple Silicon, and zsh or bash**. On Intel, Rosetta, and Windows, the installer exits without installing. It runs with macOS's `/bin/bash` and has been checked with Bash 3.2.57. Python and Node.js do not need to be installed beforehand.

Installation requires an internet connection and permission to install Homebrew. The official Homebrew installer may request administrator authentication and installation of Xcode Command Line Tools. **Do not run the entire script with `sudo`.** See the [Homebrew installation requirements](https://docs.brew.sh/Installation).

The full CLI has not been implemented yet. When runtime dependencies are added, document their versions, dependency declarations, lockfiles, and execution commands together.

## Running Lite

Run all commands below from the repository root. You can inspect the plan without making changes first.

```bash
/bin/bash installers/macos/install.sh --dry-run
```

Start initial setup with the following command. It prepares the entire [Lite installation specification](docs/specification.md#lite-installation-specification), with no options to select or exclude tools.

```bash
/bin/bash installers/macos/install.sh
```

An ASCII Shelter Lite logo appears once at the start of installation and `--dry-run`. The default output announces the start of initial setup and summarizes the final result as **installation complete or installation failed**, followed by a short explanation and next steps. On a Mac without Homebrew, the official initial installer's confirmation and administrator authentication prompts are shown directly in the terminal.

| Message | What it explains |
| --- | --- |
| `● note:` | The start of setup, or how to inspect the log and retry after a failure |
| `● success:` | Development tools are ready |
| `● error:` | Why installation or configuration could not be completed |
| `● warning:` | New executable paths require a restart, or changes already made remain after a failure |

Warnings appear only when relevant. If no new executable paths were added, the path activation warning is omitted. If execution stopped before installation or shell configuration began, the warning about retained changes is also omitted. Message categories and text remain visible with colors disabled.

The final result is shown as a heading and messages without separator lines. Each message starts with `●`, followed by a lowercase English prefix and colon without brackets. Messages, result headings, help, and logs are in English for both previews and installation workflow tests, as well as the actual installer. **For ordinary messages, only `●` receives the status color; the prefix and body use the terminal's default color.** Success is green, failures and errors are red, notes are cyan, and warnings are yellow. Result headings such as `Installation complete`, `Installation failed`, and `Check required` use the status color for the entire heading. Ordinary headings and detailed table text have no assigned color; table rows show status colors only on the leading `●`.

Section headings, table headers, installation plan items, and configuration paths use a PUA icon followed by one space in place of their former indentation. Icons are managed by `shelter_icon` in `messages.sh` using the Font Awesome mappings in [Nerd Fonts v3.5.0](https://github.com/ryanoasis/nerd-fonts/blob/v3.5.0/glyphnames.json). Displaying these icons requires a terminal font or fallback font that supports those mappings. Status messages and tool rows retain their existing `●`, colors, and spacing.

Colors are enabled by default in the installer and tests, including `--dry-run` and `--check`. No color option is required, and terminal settings are not changed.

```bash
/bin/bash installers/macos/install.sh
```

The default `always` mode emits colors even with `NO_COLOR`, `TERM=dumb`, or redirected output. Use `--color auto` to follow terminal detection and `NO_COLOR`, or `--color never` to disable colors. Output viewers that do not support ANSI colors may not display them even with `always`.

Both the installer and test commands still accept `--color` without a value as shorthand for `--color always`, which is now the default. To inspect the installation plan with colors:

```bash
/bin/bash installers/macos/install.sh --dry-run
```

See [README Usage](./README.md#usage) for results and post-installation steps. See the [command reference](docs/specification.md#command-reference) for all options and exit codes. For repository checks, use `/bin/bash installers/macos/install.sh --check`.

Each installation log is readable and writable only by its owner and contains no color codes.

### Existing Environments and Reruns

- Existing versions that run successfully are not reinstalled or directly upgraded to match a target version. New Node.js installations use `node@24`; new Python installations use uv's `3.14` series. Patch versions and versions of other tools follow what the package manager provides at installation time.
- If only one of Node.js and npm is present, or an existing command fails to run, execution stops before changes are made. For Python and uv, only missing components can be installed. `/usr/bin/python3` remains the macOS developer tools' Python, and a separate user Python installation is prepared.
- uv's Python lookup does not use the network or the existing cache. Lookup errors are shown as `Check required`. Python is treated as missing only when a successful lookup finds no installed Python.
- VS Code is detected in `/Applications` or the user's `~/Applications` folder. The app is installed using [Homebrew's `--no-binaries`](https://docs.brew.sh/Manpage), preserving an existing `code` command if it belongs to Cursor or another editor. In that case, launch VS Code from the Applications folder.
- Ghostty is detected at `/Applications/Ghostty.app` or `~/Applications/Ghostty.app`, even if the `ghostty` command is not on `PATH`. A working app is preserved; a missing app is installed with `brew install --cask ghostty`. A damaged app or a failed version check stops setup. Shelter does not change Ghostty settings, fonts, or the default terminal.

For user setup and retry steps, see [README Usage](./README.md#usage). An error stops subsequent installation; completed changes remain. Homebrew handles dependency changes needed by newly installed packages.

Each `brew install` runs with environment variables that disable automatic updates, post-install cleanup, and automatic upgrades of an already installed target package. Dependency compatibility is left to Homebrew. See the [Homebrew command documentation](https://docs.brew.sh/Manpage) for the relevant behavior.

### Shell Configuration and Backups

Required executable paths are appended to the current `PATH`, preserving the priority of existing configurations such as nvm, mise, and pyenv. If paths were added, they are saved in the locations below and connected to the shell configuration once.

| File | Change |
| --- | --- |
| `${XDG_CONFIG_HOME:-$HOME/.config}/shelter/env.sh` | Executable paths added by Shelter; an existing user-owned configuration file is not overwritten |
| `${ZDOTDIR:-$HOME}/.zshrc` | Load the environment file for zsh users |
| `$HOME/.bashrc`, `$HOME/.bash_profile` | Load the environment file for bash users |

Before modifying existing files, backups named `env.sh.backup.*` or `shell.backup.*` are created in the same directory as the environment file, and their paths are recorded in the installation log. Existing shell configuration content is preserved, and the load statement is appended. Completed changes and backups remain even if an error leaves configuration only partially applied.

Open a new terminal to activate the paths. To apply them immediately in the current terminal, run the `source` command recorded in the installation log. Restart running editors so they use the new environment. Following [uv's policy for versioned Python executables](https://docs.astral.sh/uv/guides/install-python/), new Python installations provide `python3.14` without replacing the system's `python3` or `python`.

If you need to restore a backup, compare the original and backup paths recorded in the log before restoring. To preserve other shell configuration, you can instead remove only the load statement marked `# Shelter Lite`. This does not uninstall any programs.

## Windows Lite

Run the following commands from the repository root in PowerShell. The Windows installer targets Windows 11 x64 and native Windows PowerShell 5.1. Run without elevation; individual packages may request UAC approval. Node.js and Python are not prerequisites.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --dry-run
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/install.ps1 --version
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Color never
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Preview warning
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/tests/test.ps1 -Install failure
powershell.exe -NoProfile -ExecutionPolicy Bypass -File installers/windows/build.ps1
```

With no options, `install.ps1` installs the complete fixed Windows specification. Options and exit codes match macOS for `--dry-run`, `--check`, `--version`, `--mode lite`, and `--color`. Ctrl+C uses the host's native interruption behavior. `-Preview` accepts `notification`, `warning`, `failure`, or `success`; `-Install` accepts `success`, `failure`, or `dry-run`. Workflow tests use temporary files and mocks, never actual package installations.

`messages.ps1` is the Windows message SSOT consumed by installation, builds, and tests. It preserves macOS's English prefixes, status-dot colors, result headings, PUA icons, and default `always` color policy. It does not require Bash to run. `scripts/version.ps1` reads the same root `VERSION` with the same SemVer contract as `scripts/version.sh`.

Missing WinGet uses the official current-user `Microsoft.WinGet.Client` repair path through PowerShell Gallery. Package IDs and Windows-specific policies are in the technical specification. Installation accepts source and package agreements, uses exact IDs, the `winget` source, and `--no-upgrade`. Node.js is selected from available 24.x versions rather than the package's latest major. Existing working versions are retained; partial Node/npm or broken executables stop preflight. Store Python aliases are ignored. Python and uv can be completed independently; uv discovery is offline and new Python uses `3.14`.

Only missing executable directories are appended to the raw user PATH after an ACL-protected JSON backup. Existing variable references and registry value type are preserved. Machine PATH and PowerShell profiles are not edited. Logs and PATH backups are readable by the current user and SYSTEM under `%LOCALAPPDATA%\Shelter\logs`. Restart terminals and editors after setup; Git identity and GitHub authentication are manual.

The build produces `shelter-lite-windows.ps1`, `shelter-lite-windows.zip`, their `.sha256` sidecars, and `VERSION` in `dist/`. The ZIP contains `Shelter Lite.cmd`, the standalone `.ps1`, and `VERSION`; keep the two executable files together. The `.ps1` embeds its version and MIT license. ZIP timestamps are fixed for reproducibility on the same toolchain. Use `build.ps1 -OutputDirectory "C:\path with spaces"` for another output location.

The launcher starts native Windows PowerShell without profiles and with a process-only execution-policy override. It preserves exit codes and pauses only when no arguments are supplied. It does not bypass managed policies. Scripts are unsigned. Tests do not establish that SmartScreen, App Installer repair, UAC, or a clean Windows 11 installation work on every device; complete the acceptance checks before publishing `v0.2.0`.

### Test Windows behavior on macOS

Prepare PowerShell 7 for macOS using [Microsoft's installation or binary-archive instructions](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-macos). Run the commands below from the repository root. `pwsh` must be on your PATH; if you extracted a portable archive, replace `pwsh` with the quoted full path to its executable. Temporary paths from an earlier session are not a permanent setup.

```bash
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Color never
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Preview warning
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install success
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install failure
pwsh -NoProfile -File installers/windows/tests/test.ps1 -Install dry-run
```

These tests mock Windows, package installation, registry access, and log permissions; they use temporary files and do not install tools or modify user settings. `-Install failure` returns test exit code `0` when the expected installer failure is observed. A message preview displays only that message state.

PowerShell 7 is used here to test logic on the Mac. The actual Windows installer still requires Windows PowerShell 5.1. WinGet bootstrap, UAC, Windows permissions, and `.cmd` execution need Windows validation; direct execution of `install.ps1` on macOS is rejected.

## Adding and Changing Directories

Use [Repository Structure in the technical specification](docs/specification.md#repository-structure) as the reference for the overall layout and each path's responsibility.
The macOS runtime consists of `install.sh`, `messages.sh`, `scripts/version.sh`, and `tools.sh`, with the product version in the root `VERSION` file; `build.sh` packages them, and `tests/test.sh` validates the source and standalone installer. `dist/` contains generated output and is excluded from Git. Add further paths only as their functionality is implemented.

1. **Manage the Lite installation workflow.** Keep environment checks, the fixed specification, and installation order in `installers/macos/install.sh`. Keep tool-specific checks, installation, and shell configuration functions in `tools.sh`. Consider separate `lib/`, `tools/`, or `profiles/` directories only when a real need to split them arises.
2. **Connect installation of the full version.** When the full CLI and its distribution artifacts are ready, add its workflow to the same `install.sh` under `full` mode and reuse the tool installation functions. Currently, that mode exits after a message that it is not yet available.
3. **Implement the full CLI separately.** The Python package scaffold is in `src/shelter/`, package-manager adapters belong in `src/shelter/providers/`, and CLI tests belong in the root `tests/`. uv will manage development environments and dependencies. Only package markers and a test-directory placeholder exist; root `pyproject.toml`, `uv.lock`, runtime/dependency versions, commands, and CLI tests are not implemented yet. There is no CLI install/run command at this stage. Work from the repository root and follow the [CLI discovery and update reporting plan](docs/plans/shelter-cli.md) for implementation and verification order. Keep Lite installation logic in the existing OS installers and delegate to it from the future CLI. Do not duplicate ongoing security notification and update management features in the installer.

Manage shell installer tests in `installers/macos/tests/`. When adding behavior for a version, check both the shared installation workflow and the behavior of each version. Record the working directory and actual commands in this document.
The website is managed outside this repository. The layout of the collection service and data formats will be decided after the integration scope is defined. Windows scripts, launcher, tests, and packaging live in `installers/windows/`; see the [Windows implementation and acceptance checks](./docs/plans/windows-lite.md).

When adding or changing structure, include the following documentation updates in the same change:

- Reflect actual paths in the technical specification's **Current Structure** and remaining work in **Component Responsibilities**.
- Document installation, execution, and validation commands for the component in CONTRIBUTING, including the working directory.
- Add detailed designs or separate plans to `docs/` when needed, and link them from related documents. Do not create subdirectories merely to classify future documents.

Installers for Lite and the full version share the same location, while the installer and full CLI implementation have separate responsibilities. If Homebrew distribution is chosen, define where the Formula and Tap are managed as part of the distribution process.

## Workflow

1. Read the README for usage and the technical specification in `docs/` for implementation scope.
2. Define the change and create a working branch.
3. Update the related documentation and code together.
4. Complete the checks below and review the diff.
5. Record the purpose of the change and validation results, then commit and push with the maintainer's approval.

The following is an example branch name. If it already exists, use another name appropriate for the work.

```bash
git switch -c docs/update-introduction
```

Preserve work already in progress, and do not mix unrelated changes into the same change.

## Writing Documentation

The **README** covers the product, specifications, installation, and usage. Detailed specifications, technology choices, plans, and repository structure belong in `docs/`.
**CONTRIBUTING** is the maintainer guide for source setup, development, checks, commits, and distribution, including the current contribution policy.

Maintain the English README and CONTRIBUTING at the repository root, the Korean versions in `language/ko/`, and the Japanese versions in `language/jp/`, with the same content and structure. The language table at the top of each document links to the corresponding document in another language. Commands in this document are relative to the repository root.

- Follow the section structure of the [Standard Readme specification](https://github.com/RichardLitt/standard-readme/blob/main/spec.md). Maintain a table of contents and keep the license last. Translation files use this project's `language/<language>/README.md` layout instead of the specification's `README.<language>.md` naming convention.
- Keep the short description consistent across the README, future package metadata, and the GitHub repository description.
- Distinguish current behavior from development plans. Do not present commands, directories, or distribution URLs that do not exist as available.
- When writing for non-developers, explain the problem and next action first, and define technical terms on first use.
- Include verified versions and reference files in technical specifications. Mark undecided versions as `Undecided`.
- When explaining security issues and updates, distinguish the original source, verification date, affected versions, and fixed versions. Mark unverified information as an estimate.

Move lengthy designs to the relevant document in `docs/` and link to it from the README. Group documents by topic as they accumulate, and avoid duplicating the same content across multiple files.

## Implementation and Validation

### Message Previews

Edit shared copy in [messages.sh](./installers/macos/messages.sh). Add a message key and a fixed template to `shelter_copy`, then pass variable values as arguments, for example `shelter_error install_failed "$name"`. `shelter_error` writes to stderr and saves the failure reason; the caller decides when to stop with `return` or `exit`. Use `shelter_message <tone> <key> [arguments...]` for guidance and `shelter_notice` for the shared start, warning, success, and failure displays. Keep internal status values separate from display text. Tests call the shared messages while keeping expected output literals independent so they can detect unintended wording or formatting changes.

**To inspect only the wording and explanation for each state**, pass the state after `--preview` from the repository root. Colors are enabled without extra options.

```bash
/bin/bash installers/macos/tests/test.sh --preview notification
/bin/bash installers/macos/tests/test.sh --preview warning
/bin/bash installers/macos/tests/test.sh --preview failure
/bin/bash installers/macos/tests/test.sh --preview success
```

| State | `●` color (also used for result headings) | Message shown |
| --- | --- | --- |
| `notification` | Cyan | A notice that initial setup is starting |
| `warning` | Yellow | Paths need to be activated by reopening the terminal and editor |
| `failure` | Red | An installation failure heading and an example reason |
| `success` | Green | An installation complete heading and confirmation that development tools are ready |

Previews call only the message functions shared with the actual installer. They do not inspect installed tools or create temporary files. `--preview` without a state shows `success`. Colors are enabled by default. Use `--color auto` to follow the user's terminal settings, or `--color never` to inspect plain output.

### Installation Workflow Tests

**To run the actual installer's complete workflow in a temporary environment**, use `--install`.

```bash
/bin/bash installers/macos/tests/test.sh --install
```

The test starts with an environment without the tools and runs the actual installer code, from Homebrew setup through fixed-specification installation, result checks, and shell configuration. Downloads and package installation commands are replaced by fake tools. Programs and shell settings on the actual computer are not changed. Test files and logs are removed automatically on exit.

The official option spelling is `--install`; `--intall` is also accepted with the same behavior. The scenario names below are test conditions, not options for selecting tools to install.

```bash
# Fail during uv installation and stop subsequent installation steps
/bin/bash installers/macos/tests/test.sh --install failure

# Inspect the installation plan in the test environment
/bin/bash installers/macos/tests/test.sh --install dry-run
```

`--install success` is the default scenario. In the failure scenario, the internal installer's exit code `1` is the expected result. The test command exits with `0` when the result matches expectations, `1` when it does not, and `2` for invalid options. A separate test error is printed only for unexpected results. `--preview` and `--install` cannot be combined.

Use `install.sh --dry-run` to read the current Mac's actual state and inspect the installation plan. For real initial setup, use the command without options in [Running Lite](#running-lite).

### Shell Validation

Run syntax checks and tests using temporary environments from the repository root. No separate test package is required.

```bash
for script in scripts/*.sh installers/macos/*.sh installers/macos/tests/test.sh; do
  /bin/bash -n "$script" || exit 1
done
/bin/bash installers/macos/tests/test.sh
```

Tests replace Homebrew, downloads, installation commands, and platform detection, writing results only to temporary directories. They do not modify actual programs or user shell settings. They cover fixed-specification installation, preservation of existing versions, reruns, installation failures, invalid options, unsupported environments, configuration backups, and preservation of another editor's `code` command. They also check separation of concise output and detailed logs, log permissions, colors on `●` and result headings with default-colored message bodies, state previews, and the isolation and exit codes of installation workflow tests. Ghostty tests cover keeping an existing app outside `PATH`, detecting damaged apps, installation failure and retry, and verification after installation.

Packaging tests also verify checksums, reproducible output, running help after relocating a single file, and loading it without starting installation. The installation and `--dry-run` output checks that the ASCII logo appears once. ZIP checks also cover executable permissions after macOS extraction, standalone execution, preserved exit codes, and reproducible archive contents.

On a supported Mac, also check these read-only commands:

```bash
/bin/bash installers/macos/install.sh --help
/bin/bash installers/macos/install.sh --dry-run
/bin/bash installers/macos/install.sh --check
```

Separately verify that actual downloads and installation finish on a new Mac, that tools run in Ghostty, a new terminal, and VS Code, and that reruns do not duplicate installations or configuration. **Real-device checks cover read-only execution on macOS 26.6.2. Hosted-runner CI coverage is listed below; a complete fresh installation has not been verified.**

### Verified CI coverage

The `0.2.0` implementation passed [CI run 41794242682](https://github.com/4BFC/shelter/actions/runs/41794242682) on 2026-11-04. The rows distinguish the two platforms and their test runtimes; each count is a separate successful suite.

| Platform | Source tests | Extracted ZIP tests | Runtime |
| --- | --- | --- | --- |
| macOS | 34 passed | 34 passed | macOS 15 runner, system Bash |
| Windows | 35 passed | 35 passed | Windows 2025 runner, Windows PowerShell 5.1 |

CI also checked checksums, embedded versions, and the Windows `.cmd` launcher's version output and failure exit code. Package installation and user-setting changes were mocked. The Windows Server runner does not make Windows Server an installation target. Clean Windows 11 setup, WinGet repair, UAC, and downloaded-file security prompts remain on the [acceptance checklist](./docs/plans/windows-lite.md#clean-device-acceptance-before-publishing-v020).

### Documentation and Diff Checks

Run these commands from the repository root.

```bash
git diff --check
git diff -- .gitignore README.md CONTRIBUTING.md language/ installers/macos/
git status --short
```

`git diff` shows changes only to tracked files. Review the full contents of new files separately in an editor.

Check headings, tables, code blocks, and badges in a Markdown preview, and verify the table of contents and relative links.
The license owner and year must match [LICENSE](./LICENSE).

### Validation by Feature

The release workflow runs Bash syntax checks and isolated installer tests. Add further static checks alongside the features below.

| Area of change | Behavior to verify |
| --- | --- |
| Information collection | Preserve original sources and verification dates, handle duplicate advisories, and show collection failures and stale information |
| Impact assessment | Distinguish affected and unaffected versions and fixed versions; do not label an unknown state as safe |
| Computer status checks | Distinguish installed versions from actual executable paths, management tool conflicts, and unsupported environments |
| Installation and updates | Show targets and results, handle download or application failures, and document configuration backups and recovery limits |
| Notifications and guidance | Clearly explain the problem, required action, and result; indicate when a restart is needed |

Run tests that change computer settings in temporary directories or isolated environments. Do not assume automatic updates are the default before the update policy is defined.
Distinguish installing a new version from switching a running program to it. Do not report a state that still requires a restart as complete.

## Commits and Publishing

Before committing, inspect the changed files and diff, and include only the files needed for the change.
Keep commit messages short and specific. For example: `docs: clarify Shelter maintenance policy`.

When working with AI tools, review the diff first. Do not stage or commit without an explicit instruction from the user, and do not add `Co-Authored-By` to commits.

Personal Claude/Codex directories (`.claude/`, `.codex/`, `.agents/`), Claude state files (`.claude.json*`), local instruction overrides (`CLAUDE.local.md`, `AGENTS.local.md`, `AGENTS.override.md`), and `.mcp.local.json` are excluded by `.gitignore`. Keep personal paths and credentials in those local files. Shared project instructions in `CLAUDE.md` and `AGENTS.md` can be tracked.

Before publishing, record the following in the change summary:

- The problem being solved and the resulting behavior
- Commands checked, their results, and validation that could not be performed
- Constraints or follow-up work that users should know about

For documentation changes, report link and preview checks. For functional changes, provide reproducible validation results.
Publish only the changes approved by the maintainer. External pull requests and issues are not part of this workflow.

## Distribution

### Double-click installation

User installation steps and macOS security guidance are in [README Install](./README.md#install).

The `.command` file contains the complete installer. ZIP preserves its executable permission so users do not need to type `chmod`. When launched interactively without arguments, it waits for Return before exiting, including after an installation failure. Command-line options such as `--dry-run` still work.

### Build and validate distribution files

Build the standalone Shelter Lite installer from the repository root. Packaging uses macOS's Bash and standard command-line tools; it does not download or install programs.

```bash
/bin/bash installers/macos/build.sh
```

The generated files are:

```text
dist/
├── shelter-lite-macos.sh        # Standalone installer
├── shelter-lite-macos.sh.sha256 # SHA-256 checksum
├── shelter-lite-macos.zip       # Double-click installer ZIP
├── shelter-lite-macos.zip.sha256 # SHA-256 checksum
└── VERSION                     # Product version, source of truth
```

The `.sh` file embeds `install.sh`, `messages.sh`, `scripts/version.sh`, `tools.sh`, the product version, and the MIT license. The ZIP also includes a readable `VERSION` file; `Shelter Lite.command` runs independently of it. `dist/VERSION` is attached to the release separately. It can run by itself from any folder. `dist/` is excluded from Git; edit the sources and rebuild instead of editing the generated file. Unchanged sources produce identical output. To choose another output directory, use `--output-dir "/path/with spaces"`.

Verify the checksum and run the isolated test suite against the bundled code:

```bash
(cd dist && shasum -a 256 -c shelter-lite-macos.sh.sha256)
(cd dist && shasum -a 256 -c shelter-lite-macos.zip.sha256)
/bin/bash dist/shelter-lite-macos.sh --help
SHELTER_TEST_INSTALLER="$PWD/dist/shelter-lite-macos.sh" /bin/bash installers/macos/tests/test.sh
```

User installation steps and macOS security guidance are in [README Install](./README.md#install).

The same macOS 15+, native Apple Silicon, zsh/bash support and internet requirements apply. The installer displays the Shelter Lite ASCII logo at the start of installation and `--dry-run`. Packaging and isolated tests do not validate a complete installation on a new Mac; that check has not been performed yet. Homebrew distribution and a remote one-command installer remain planned.

### Versioning

The native helpers [scripts/version.sh](./scripts/version.sh) and [scripts/version.ps1](./scripts/version.ps1) read and validate the same product metadata without depending on the installer. Callers choose how to display errors.

Editing `VERSION`, building files, or pushing source changes does not publish a release or create a tag. Prepare and validate the sources and files first; tag selection and GitHub Release publication are separate maintainer actions. No local tag command is required during preparation.

The root [VERSION](./VERSION) is the single source of truth for Shelter Lite's product version. Use [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html) without the leading `v`, for example `0.1.0` or `0.2.0-rc.1`. Supported prerelease identifiers and optional `+build.metadata` follow SemVer syntax.

During `0.x` development, this project increments PATCH for compatible fixes and MINOR for features or compatibility changes. Declare the first stable command and installation contract with `1.0.0`. After that, incompatible changes increment MAJOR, compatible features increment MINOR, and compatible fixes increment PATCH. A major or minor increment resets the lower components to zero. Release candidates use suffixes such as `0.2.0-rc.1`.

1. Edit `VERSION` for the next release. Commit the version and implementation together; published version tags must not be moved to changed code.
2. Rebuild with the platform's `build.sh` or `build.ps1`. The `.sh`, `.command`, and `.ps1` installers embed the version, and each ZIP and `dist/VERSION` record the same value. Changing the source `VERSION` does not change already-built files.
3. Publish a GitHub Release whose tag is exactly `v` plus `VERSION`: for `0.2.0`, use `v0.2.0`. Mark release candidates as pre-releases in GitHub. The workflow stops before building or uploading if the tag differs. It validates and packages the chosen version; it does not increment the number.

```bash
/bin/bash installers/macos/install.sh --version
/bin/bash installers/macos/build.sh
/bin/bash dist/shelter-lite-macos.sh --version
cat dist/VERSION
```

`--version` prints `Shelter Lite <version>` without platform checks, downloads, or configuration changes. Product metadata uses `SHELTER_RELEASE_VERSION`; `SHELTER_VERSION` remains the observed version of a tool being checked.

### Automated release assets

[release.yml](./.github/workflows/release.yml) runs when a GitHub Release is published, including pre-releases. It calls [validate.yml](./.github/workflows/validate.yml), which validates the release tag against `VERSION`, tests source and extracted ZIP installers, builds both platforms, and checks checksums and embedded versions. macOS uses a macOS 15 runner; Windows uses Windows PowerShell 5.1 on a Windows 2025 runner for mocked tests. Both jobs must succeed before the publish job uploads all nine assets: two installers and two checksums per platform, plus the shared `VERSION`.

The validation workflow also runs for implementation changes pushed to `main` and can be started manually. These runs do not publish release assets.

1. Commit and push the workflow and installer sources to GitHub. Choose a release tag whose commit includes this workflow and the intended source version.
2. In GitHub **Releases**, create a release with that tag and click **Publish release**. Saving a draft or pushing a tag alone does not trigger this workflow.
3. Wait for **Release Shelter Lite** in Actions to succeed, then download the ZIP for your platform from **Assets**. The standalone `.sh` and `.ps1` files, four checksum files, and shared `VERSION` are attached as well.

The workflow uses the repository's built-in `GITHUB_TOKEN` with `contents: write`; no separate release token is needed. Test or build failures stop the upload. After resolving a failure, rerun the job in Actions; uploads replace assets with the same names. This workflow attaches files to an existing release and runs isolated tests, so it does not verify a full installation on a new Mac or Windows PC.

Distinguish updating Shelter itself from Shelter updating software on the user's computer.
### Release notes

Write release notes only in the GitHub Release body; the repository keeps no separate notes file. Write them in English, like the installer messages. Start with a centered heading and a one-sentence summary. Under **New**, list only added features, grouped by platform; include **macOS** and **Windows** sections for the platforms changed in the release. End with a **Download** table listing each installer file with its platform, requirements, and checksum link. File links work after the workflow finishes uploading.

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
