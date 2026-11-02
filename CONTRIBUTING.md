# Contributing

| English | 한국어 | 日本語 |
| --- | --- | --- |
| **Current** | [한국어](./language/ko/CONTRIBUTING.md) | [日本語](./language/jp/CONTRIBUTING.md) |

This guide explains how to improve Shelter's documentation and contribute to its development.
See the [README](./README.md) for the project's purpose, components, and technical direction.

Shelter Lite for macOS, tests using temporary environments, and local script and double-click ZIP packaging are available. The full CLI, CI, and public release automation are not yet ready.

## Table of Contents

- [Questions and Suggestions](#questions-and-suggestions)
- [Development Setup](#development-setup)
- [Running Lite](#running-lite)
- [Adding and Changing Directories](#adding-and-changing-directories)
- [Workflow](#workflow)
- [Writing Documentation](#writing-documentation)
- [Implementation and Validation](#implementation-and-validation)
- [Commits and Pull Requests](#commits-and-pull-requests)
- [Distribution](#distribution)

## Questions and Suggestions

Use [Issues](https://github.com/4BFC/shelter/issues) for questions, bug reports, and feature suggestions.
Documentation changes and pull requests are welcome. Before implementation, agree on the scope with the maintainer for technology choices, additional operating systems, and major features.

Include the following in a proposal:

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

On a new Mac without Git, use **Code → Download ZIP** on GitHub to download the full source, extract it, and enter the extracted folder in your terminal. Keep `install.sh`, `messages.sh`, and `tools.sh` together.

The standalone distribution file includes these three files internally; see [Distribution](#distribution) for how to build and use it.

### Runtime Environment

The installation target is **macOS 15 or later, Apple Silicon, and zsh or bash**. On Intel, Rosetta, and Windows, the installer exits without installing. It runs with macOS's `/bin/bash` and has been checked with Bash 3.2.57. Python and Node.js do not need to be installed beforehand.

Installation requires an internet connection and permission to install Homebrew. The official Homebrew installer may request administrator authentication and installation of Xcode Command Line Tools. **Do not run the entire script with `sudo`.** See the [Homebrew installation requirements](https://docs.brew.sh/Installation).

The full CLI has not been implemented yet. When runtime dependencies are added, document their versions, dependency declarations, lockfiles, and execution commands together.

## Running Lite

Run all commands below from the repository root. You can inspect the plan without making changes first.

```bash
/bin/bash installers/macos/install.sh --dry-run
```

Start initial setup with the following command. It prepares the entire [Lite installation specification](./README.md#lite-installation-specification), with no options to select or exclude tools.

```bash
/bin/bash installers/macos/install.sh
```

After setup, open Ghostty from the Applications folder or run:

```bash
open -a Ghostty
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

Version tables, individual installation results, package installer output, and shell configuration changes are recorded in `${XDG_CONFIG_HOME:-$HOME/.config}/shelter/logs/install.*`. Each run creates a new log that only its owner can read and write, without color codes. Logs are kept after successful runs as well. In the log, `Not run` means a step was skipped because an earlier step failed. Use `--check` for details about current versions and executable paths.

After installation, open a new terminal, enter the repository root, and check the results.

```bash
/bin/bash installers/macos/install.sh --check
echo $?
```

If every item is marked `Installed` and the exit code is `0`, all tools can run. `--dry-run` states at the beginning and end that it makes no actual changes; it does not display actual installation results.

| Option | Behavior |
| --- | --- |
| No options | Run the complete Lite initial setup |
| `--dry-run` | Show the installation plan only; no downloads or configuration changes |
| `--check` | Check whether all tools run; no downloads or configuration changes |
| `--mode lite` | Same as the default |
| `--mode full` | Exit with a message that it is not yet available; do not install |
| `--color auto\|always\|never` | Automatic colors, always-on colors (default), or plain output |
| `--color` | Force colors for this run; same as `--color always` |
| `--help` | Show help |

Exit codes are `0` for success, `1` for missing tools or execution/installation errors, `2` for invalid options or unsupported environments, and `130` for interruption with Ctrl+C. `--check` and `--dry-run` cannot be combined. A preview that successfully produces an installation plan exits with `0`, even if some tools are missing.

### Existing Environments and Reruns

- Existing versions that run successfully are not reinstalled or directly upgraded to match a target version. New Node.js installations use `node@24`; new Python installations use uv's `3.14` series. Patch versions and versions of other tools follow what the package manager provides at installation time.
- If only one of Node.js and npm is present, or an existing command fails to run, execution stops before changes are made. For Python and uv, only missing components can be installed. `/usr/bin/python3` remains the macOS developer tools' Python, and a separate user Python installation is prepared.
- uv's Python lookup does not use the network or the existing cache. Lookup errors are shown as `Check required`. Python is treated as missing only when a successful lookup finds no installed Python.
- VS Code is detected in `/Applications` or the user's `~/Applications` folder. The app is installed using [Homebrew's `--no-binaries`](https://docs.brew.sh/Manpage), preserving an existing `code` command if it belongs to Cursor or another editor. In that case, launch VS Code from the Applications folder.
- Ghostty is detected at `/Applications/Ghostty.app` or `~/Applications/Ghostty.app`, even if the `ghostty` command is not on `PATH`. A working app is preserved; a missing app is installed with `brew install --cask ghostty`. A damaged app or a failed version check stops setup. Shelter does not change Ghostty settings, fonts, or the default terminal.

Git identity and `gh auth login` are not configured automatically. An installation error stops subsequent steps; tools installed earlier remain. After resolving the error, rerun the same command to skip tools that are already ready. There is no rollback for the entire package installation. Homebrew handles dependency changes needed by newly installed packages.

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

## Adding and Changing Directories

Use [Repository Structure in the README](./README.md#repository-structure) as the reference for the overall layout and each path's responsibility.
The runtime consists of `install.sh`, `messages.sh`, and `tools.sh`; `build.sh` packages them, and `tests/test.sh` validates the source and standalone installer. `dist/` contains generated output and is excluded from Git. Add further paths only as their functionality is implemented.

1. **Manage the Lite installation workflow.** Keep environment checks, the fixed specification, and installation order in `installers/macos/install.sh`. Keep tool-specific checks, installation, and shell configuration functions in `tools.sh`. Consider separate `lib/`, `tools/`, or `profiles/` directories only when a real need to split them arises.
2. **Connect installation of the full version.** When the full CLI and its distribution artifacts are ready, add its workflow to the same `install.sh` under `full` mode and reuse the tool installation functions. Currently, that mode exits after a message that it is not yet available.
3. **Implement the full CLI separately.** If Python is chosen, place the implementation in `src/shelter/`, Python tests in the root `tests/` directory, and package configuration in the root `pyproject.toml`. These paths have not been created yet. Do not duplicate ongoing security notification and update management features in the installer.

Manage shell installer tests in `installers/macos/tests/`. When adding behavior for a version, check both the shared installation workflow and the behavior of each version. Record the working directory and actual commands in this document.
The website is managed outside this repository. The layout of the collection service and data formats will be decided after the integration scope is defined. A Windows installer is outside the current scope.

When adding or changing structure, include the following documentation updates in the same change:

- Reflect actual paths in the README's **Current Structure** and remaining work in **Component Responsibilities**.
- Document installation, execution, and validation commands for the component in CONTRIBUTING, including the working directory.
- Add detailed designs or separate plans to `docs/` when needed, and link them from related documents. Do not create subdirectories merely to classify future documents.

Installers for Lite and the full version share the same location, while the installer and full CLI implementation have separate responsibilities. If Homebrew distribution is chosen, define where the Formula and Tap are managed as part of the distribution process.

## Workflow

1. Read the README to understand the product direction and current implementation scope.
2. Define the change and create a working branch.
3. Update the related documentation and code together.
4. Complete the checks below and review the diff.
5. Submit a pull request explaining the purpose of the change and validation results.

The following is an example branch name. If it already exists, use another name appropriate for the work.

```bash
git switch -c docs/update-introduction
```

Preserve work already in progress, and do not mix unrelated changes into the same change.

## Writing Documentation

The **README** explains the project: its introduction, purpose, product components, technical specifications, and repository structure.
**CONTRIBUTING** explains how to change the project: installation, development, checks, commits, and distribution.

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
for script in installers/macos/*.sh installers/macos/tests/test.sh; do
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

Separately verify that actual downloads and installation finish on a new Mac, that tools run in Ghostty, a new terminal, and VS Code, and that reruns do not duplicate installations or configuration. **Validation currently covers tests in temporary environments and read-only execution on macOS 26.6.2. The complete real initial installation has not been verified.**

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

Static analysis tools beyond the shell tests and CI are not yet available. Add the corresponding checks when implementing the features below.

| Area of change | Behavior to verify |
| --- | --- |
| Information collection | Preserve original sources and verification dates, handle duplicate advisories, and show collection failures and stale information |
| Impact assessment | Distinguish affected and unaffected versions and fixed versions; do not label an unknown state as safe |
| Computer status checks | Distinguish installed versions from actual executable paths, management tool conflicts, and unsupported environments |
| Installation and updates | Show targets and results, handle download or application failures, and document configuration backups and recovery limits |
| Notifications and guidance | Clearly explain the problem, required action, and result; indicate when a restart is needed |

Run tests that change computer settings in temporary directories or isolated environments. Do not assume automatic updates are the default before the update policy is defined.
Distinguish installing a new version from switching a running program to it. Do not report a state that still requires a restart as complete.

## Commits and Pull Requests

Before committing, inspect the changed files and diff, and include only the files needed for the change.
Keep commit messages short and specific. For example: `docs: add Shelter introduction and contribution guide`.

When working with AI tools, review the diff first. Do not stage or commit without an explicit instruction from the user, and do not add `Co-Authored-By` to commits.

Include the following in a pull request:

- The problem being solved and the resulting behavior
- Commands checked, their results, and validation that could not be performed
- Constraints or follow-up work that users should know about

For documentation changes, report link and preview checks. For functional changes, provide reproducible validation results.
Link a related issue if one exists. Do not automatically create unrelated issues or separate pull requests outside the contribution's scope.

## Distribution

### Double-click installation

1. Download `shelter-lite-macos.zip` and double-click the ZIP to extract it.
2. Double-click the extracted `Shelter Lite.command`. Terminal opens and starts setup; Homebrew does not need to be installed beforehand.
3. Respond to Homebrew confirmations or administrator authentication if requested. After reading the final result, press Return to finish.

The `.command` file contains the complete installer. ZIP preserves its executable permission so users do not need to type `chmod`. When launched interactively without arguments, it waits for Return before exiting, including after an installation failure. Command-line options such as `--dry-run` still work.

The ZIP contains an unsigned script. Downloaded files may require macOS security confirmation; see [Apple's guidance](https://support.apple.com/en-us/102445). Browser-download, Gatekeeper, and Finder launch behavior still need real-device validation.

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
└── shelter-lite-macos.zip.sha256 # SHA-256 checksum
```

The `.sh` file embeds `install.sh`, `messages.sh`, `tools.sh`, and the MIT license. It can run by itself from any folder. `dist/` is excluded from Git; edit the sources and rebuild instead of editing the generated file. Unchanged sources produce identical output. To choose another output directory, use `--output-dir "/path/with spaces"`.

Verify the checksum and run the isolated test suite against the bundled code:

```bash
(cd dist && shasum -a 256 -c shelter-lite-macos.sh.sha256)
(cd dist && shasum -a 256 -c shelter-lite-macos.zip.sha256)
/bin/bash dist/shelter-lite-macos.sh --help
SHELTER_TEST_INSTALLER="$PWD/dist/shelter-lite-macos.sh" /bin/bash installers/macos/tests/test.sh
```

Share the `.sh` and checksum files together. Users who save them in Downloads can verify the file and inspect the plan as follows:

```bash
cd ~/Downloads
shasum -a 256 -c shelter-lite-macos.sh.sha256 && /bin/bash shelter-lite-macos.sh --dry-run
```

After reviewing the plan, start installation:

```bash
/bin/bash shelter-lite-macos.sh
```

The same macOS 15+, native Apple Silicon, zsh/bash support and internet requirements apply. The installer displays the Shelter Lite ASCII logo at the start of installation and `--dry-run`. Packaging and isolated tests do not validate a complete installation on a new Mac; that check remains required before a public release. Public release automation, Homebrew distribution, and a remote one-command installer remain planned.

Distinguish updating Shelter itself from Shelter updating software on the user's computer.
Release notes should include changes, the support scope, and known constraints. Publish only after verifying installation and updates.
