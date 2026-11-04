# Shelter Lite for Windows: implementation and acceptance

Status: implemented for the `0.2.0` source version; release and clean-device acceptance are pending. Updated 2026-11-04.

This document replaces the preparation-only plan. The Windows implementation is under `installers/windows/`. It does not change the macOS installation policy. A version bump does not publish a release or upload assets by itself.

## Supported contract

- Windows 11 client, native x64, Windows PowerShell 5.1. Windows 10, Server, ARM64, emulated/32-bit processes are rejected. The Windows Server CI runner is used for mocked tests only.
- Start as a regular, non-elevated user. Individual machine-scoped installers can request UAC authentication. Restricted accounts and organization policies may prevent setup.
- Install the entire fixed specification without tool selection: WinGet, Git, VS Code, Windows Terminal, Node.js 24/npm, Python 3.14/uv, and GitHub CLI.
- Preserve working tools, including versions outside the new-install target series. Stop on broken commands or a partial Node/npm pair. Complete Python and uv independently when only one is missing.
- Keep terminal settings, PowerShell profiles, machine PATH, version-manager priority, Git identity, and GitHub authentication. Append missing executable directories to user PATH only after a raw-value backup, preserving registry type and variable references.
- Stop on installation or verification failure. Retain completed changes and provide a log and retry guidance; no package rollback is attempted.

## Package sources and probing

WinGet package IDs were checked in the [official Microsoft manifest repository](https://github.com/microsoft/winget-pkgs/tree/master/manifests) on 2026-11-04: `Git.Git`, `Microsoft.VisualStudioCode`, `Microsoft.WindowsTerminal`, `OpenJS.NodeJS.LTS`, `astral-sh.uv`, and `GitHub.cli`. These IDs are selection inputs, not pinned package versions. Runtime logic is the authority in [tools.ps1](../../installers/windows/tools.ps1).

- Missing WinGet follows Microsoft's current-user `Microsoft.WinGet.Client` repair path using PowerShell Gallery and its NuGet provider. It enables TLS 1.2 only for the bootstrap and restores the prior process setting. A broken existing WinGet blocks setup instead of being silently replaced. See [Microsoft's WinGet guidance](https://learn.microsoft.com/en-us/windows/package-manager/winget/) and the [repair cmdlet](https://github.com/microsoft/winget-cli/blob/master/src/PowerShell/Help/Microsoft.WinGet.Client/Repair-WinGetPackageManager.md).
- Installs use exact package IDs, the `winget` source, `--no-upgrade`, silent installers, and explicit source/package agreement acceptance. UAC remains visible. A nonzero result, including a restart requirement, stops setup; retry after resolving the result. See [WinGet install options](https://learn.microsoft.com/en-us/windows/package-manager/winget/install).
- VS Code must have its actual `Code.exe` next to the expected `bin/code.cmd`; Cursor's command is not sufficient. Windows Terminal is checked through its registered package and executable without launching its GUI.
- The Node.js LTS package can move to another major. Query its available versions and request the highest 24.x explicitly; fail if no 24.x is offered. npm is checked through `npm.cmd`, which avoids invoking an npm PowerShell shim under restrictive execution policies.
- Store Python aliases do not count as working Python and are never executed. uv discovery uses `--offline`, `--no-cache`, `--no-config`, and `--no-python-downloads`; only an empty successful installed list establishes absence. New Python uses `uv python install 3.14`, preserving existing default/version-manager commands. See [uv Python installation](https://docs.astral.sh/uv/guides/install-python/).

## Messages, metadata, and packaging

[messages.ps1](../../installers/windows/messages.ps1) is the Windows-native SSOT used by install, build, and tests. It uses the existing English message semantics, lowercase prefixes, colored status dot, fully colored result headings, PUA section icons, and `always`/`auto`/`never` policy. No Bash, font installation, or shell profile change is needed. Icon appearance still depends on the terminal font.

The root [VERSION](../../VERSION) remains the product SSOT. [scripts/version.ps1](../../scripts/version.ps1) implements the same strict SemVer contract as the Bash helper. Both platform bundles embed `0.2.0`; a release tag must equal `v` plus VERSION. No workflow increments VERSION automatically.

[build.ps1](../../installers/windows/build.ps1) produces a UTF-8 BOM standalone `.ps1`, a ZIP containing that script, `Shelter Lite.cmd`, and `VERSION`, and SHA-256 sidecars. It embeds the MIT license and fixes ZIP timestamps. The launcher keeps the script beside it, selects native Windows PowerShell even from a 32-bit CMD host, preserves the exit code, and waits after a no-argument double-click launch.

The launcher uses `-NoProfile -ExecutionPolicy Bypass` for its child process only. It does not alter saved execution policies or bypass Group Policy. Scripts are unsigned and may trigger Windows download/security warnings. The launcher itself must be permitted by device policy; no security controls are disabled. See [PowerShell execution policies](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

Logs and user PATH JSON backups live under `%LOCALAPPDATA%\Shelter\logs` with inheritance removed and access restricted to the current user and SYSTEM. ANSI color sequences are removed from detailed logs. The backup records the prior raw PATH and whether the value was absent; restoration is a deliberate user action, not an automatic rollback.

## Automated checks

[tests/test.ps1](../../installers/windows/tests/test.ps1) covers offline preflight, dry-run/check side-effect boundaries, existing/missing/partial/broken tools, dependency order, failed installs and verification, WinGet bootstrap, Node major selection, Python lookup, PATH backup/idempotence, colors, SemVer, checksums, relocated standalone files, and ZIP reproducibility. Actual package, registry, ACL, and platform operations are mocked.

[validate.yml](../../.github/workflows/validate.yml) runs source and extracted-ZIP tests with Windows PowerShell 5.1 on `windows-2025` and the existing macOS Bash tests. It runs on implementation pushes to `main`, manual dispatch, and as the release workflow's validation gate. [release.yml](../../.github/workflows/release.yml) uploads all nine macOS/Windows assets only after both platform jobs succeed.

Local checks on the macOS development machine use a checksum-verified temporary PowerShell 7 runtime. They validate logic and packaging but do not establish Windows PowerShell 5.1 or Windows device behavior. No actual tool installation has been performed by these tests.

On 2026-11-04, [CI run 41794242682](https://github.com/4BFC/shelter/actions/runs/41794242682) passed for implementation commit `39831051c61e6b041ea8dd5f93c5206ecb9e298f`: macOS passed 34 tests against both source and extracted ZIP, and Windows PowerShell 5.1 passed 35 tests against each. Both builds passed checksum and embedded-version checks; Windows also verified the `.cmd` launcher's version output and failure exit code. These remain mocked installation tests on hosted runners, not clean Windows 11 setup acceptance.

## Clean-device acceptance before publishing v0.2.0

- [x] Run the Windows PowerShell 5.1 CI source and extracted-ZIP suites successfully (35 tests each; CI run linked above).
- [ ] Download and extract the ZIP on Windows 11 x64, test unsigned-file warnings, double-click from a path with spaces, and confirm completion/failure remains visible.
- [ ] Test a new account with and without App Installer/WinGet. Exercise PowerShell Gallery bootstrap, network failure, restricted policy, canceled UAC, and retry behavior.
- [ ] Install the full tool set, reopen terminal/editor, and run every version check. Verify that existing Node/version-manager, Python, VS Code/Cursor, and Git setups retain their priority.
- [ ] Inspect current-user log/backup ACLs, raw PATH/registry type preservation, terminal settings, profiles, Git identity, and GitHub login.
- [ ] Rerun after success and after a partial failure; verify no duplicate PATH entries and no replacement of functioning packages.

ARM64, Windows 10/Server, signed installers, silent organization deployment, uninstall/rollback automation, and Homebrew/WinGet distribution of the Shelter CLI itself are outside this release.
