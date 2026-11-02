# Shelter Lite for Windows: Preparation

Status: planning only. Reviewed on 2026-11-02.

The macOS implementation, product version, and release workflow have been committed before starting this preparation. This document records candidates and decisions needed for Windows. It does not add a Windows installer, launcher, build script, or release job. Current distribution files remain macOS-only.

## Goal

Prepare the entire fixed development tool set for users who have no development tools installed. Preserve working installations, install missing components, and present the same Shelter Lite identity, English messages, status colors, dry-run, check, and version behavior as on macOS. Users do not select individual tools.

## Candidate platform and tools

The following rows describe proposed Windows equivalents and the decisions still needed. They are not a validated Windows installation specification.

| Area | Candidate | Preparation required |
| --- | --- | --- |
| Operating system | Windows 11 | Decide supported releases and verify native x64 and ARM64 separately |
| Initial runtime | Built-in Windows PowerShell | Confirm the minimum version and avoid requiring PowerShell 7 before initial setup |
| Package installation | WinGet | Define detection, missing-client bootstrap, source agreements, UAC behavior, and failure recovery |
| Version control | Git | Verify the package ID and distinguish working installations from broken commands |
| Editor | VS Code | Detect the actual application without confusing another editor's `code` command |
| Terminal | Windows Terminal | Evaluate as the Windows counterpart to Ghostty, preserving an existing installation |
| JavaScript | Node.js 24 and npm | Verify package availability, version selection, architecture, and existing version-manager precedence |
| Python | Python 3.14 managed by uv | Verify user Python detection, App Execution Aliases, uv installation, and versioned executable paths |
| GitHub integration | GitHub CLI | Preserve existing installations and leave authentication to the user |

[WinGet is delivered through App Installer](https://learn.microsoft.com/en-us/windows/package-manager/winget/), but Microsoft documents that it can be unavailable after first login or absent from a device. The initial setup must account for both cases before requiring any `winget` command. Choose and test an official App Installer or package-manager repair path, including devices where Store access is restricted.

Ghostty's [1.4.0 roadmap](https://ghostty.org/docs/install/release-notes/1-4-0#roadmap) drops Windows GUI support. [Windows Terminal](https://learn.microsoft.com/en-us/windows/terminal/install) is therefore a candidate for this platform rather than assuming the macOS terminal package can be reused. The final Windows tool list requires confirmation before implementation.

## Boundaries to define

- Read the root `VERSION` as the product version. Future Windows packages must embed it and match the release tag. The shared version contract is platform-independent; its current Bash reader must not become a Windows prerequisite.
- Retain shared wording and status meanings. Decide how Windows presentation consumes that contract without duplicating or drifting from the existing message catalog.
- Preserve user and machine PATH entries, version-manager priority, PowerShell profiles, Git identity, and GitHub authentication. Define backups before adding any configuration changes.
- Decide a double-click entry point that preserves exit codes and keeps completion or failure visible. Evaluate execution policy, downloaded-file marking, SmartScreen, and signing; do not assume `.ps1` files execute by double-click.
- Keep OS-specific installation code under `installers/windows/` when implementation begins. Keep common product metadata and release policy at the repository level. No placeholder runtime directories are needed during preparation.

## Validation required before implementation is released

1. Confirm the Windows release and architecture matrix, runtime baseline, exact package IDs, and new-install version policy.
2. Design isolated tests for missing, existing, partial, and broken installations; download failures; retries; PATH preservation; dry-run and check behavior; and exit codes.
3. Verify initial setup on clean Windows machines with and without WinGet. Exercise administrator prompts and restricted accounts, then confirm tools run after reopening the terminal and editor.
4. Validate the downloaded double-click package, profile backups, reruns, and uninstall boundaries on Windows.
5. Add Windows packaging and a Windows release job only after the implementation and tests exist. Keep platform-specific asset names and the shared `VERSION` consistent.

No Windows installation command or downloadable Windows package is available from this preparation document.
