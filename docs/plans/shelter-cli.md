# Shelter CLI: discovery and update reporting

Status: directory scaffold only. Updated 2026-11-05. Python is the implementation direction and uv is the development environment and dependency manager. No CLI commands, package-manager adapters, Python package metadata, or standalone CLI artifacts are implemented yet.

## Initial scope

Start with the tools supported by Shelter Lite on macOS and Windows. Query the package manager's inventory and reconcile it with the executable actually selected by the user's PATH. Broader application inventory and project-level npm/pip dependencies are later extensions, not part of this first scope.

The first release of the CLI should report installed versions, executable paths, ownership, and available updates. Listing an update must not apply it. Security advisory matching and update application are separate later features; an outdated package is not necessarily vulnerable.

## Directory responsibilities

Created in this change:

```text
src/
└── shelter/
    ├── __init__.py
    └── providers/
        └── __init__.py
tests/
└── .gitkeep
```

Keep the initial implementation flat. Add the following modules when their behavior is implemented, without introducing command, service, repository, or per-tool directory layers in advance:

| Planned path | Responsibility |
| --- | --- |
| `src/shelter/cli.py` | Parse commands, invoke workflows, and select exit codes |
| `src/shelter/models.py` | Shared records for installed tools, query results, and update candidates |
| `src/shelter/inventory.py` | Combine manager inventory and executable probes without losing ownership or path information |
| `src/shelter/updates.py` | Build an update report from provider results and supported-version policies |
| `src/shelter/lite.py` | Invoke the bundled OS-specific Lite installer and preserve its exit result |
| `src/shelter/messages.py` | Own CLI-specific English text and terminal rendering, following the existing Lite conventions |
| `src/shelter/providers/homebrew.py` | Query Homebrew package identities, installed versions, and update candidates |
| `src/shelter/providers/winget.py` | Query WinGet identities, installed versions, and update candidates |
| `tests/test_*.py` | Test discovery, provider output handling, policies, rendering, and Lite delegation using fixtures |
| `pyproject.toml` | Declare the Python package, runtime requirement, dependencies, and `shelter` entry point |
| `uv.lock` | Record resolved development and runtime dependencies once package configuration exists |

The root `VERSION` remains the only manually maintained product version. Package metadata and packaged CLI version reporting must derive from it. The CLI must not import shell installer internals or copy their install logic. Lite's existing message catalogs remain the source for Lite output; CLI-specific text belongs to the CLI.

## Proposed command flow

These names describe the intended interface and are not executable commands yet:

```text
shelter                  Show help and available commands
shelter status           Show installed supported tools, versions, paths, and ownership
shelter outdated         Show available updates and explain unknown or constrained results
shelter lite --dry-run   Delegate to the existing Lite installation preview
shelter lite             Delegate to the existing fixed-set Lite installation
```

`status` must work without installing Homebrew or WinGet. A missing manager is a reported condition, not a reason to install one during inspection. `outdated` may need network access and package-source metadata; report query time, source freshness, and failures. Manager queries may refresh their own caches, but must not install or upgrade software or change user PATH/profile configuration. Network failure must not be rendered as "up to date."

## Discovery and update decisions

1. Detect the supported OS, available managers, and executable locations using structured subprocess argument lists and timeouts. Reject shell command interpolation. Treat missing, broken, and unknown states separately.
2. Normalize each observation into a record containing tool identity, provider, package ID, installed version, installation path, active executable path, and collection time. Keep multiple installations as separate observations. A Homebrew-owned Node must not be merged with an active version-manager Node solely because the display names match.
3. Ask the owning manager for update candidates. Use machine-readable output where supported; adapters must have fixtures for supported output formats, localized text, unknown versions, failures, and timeouts. Do not assume every manager supports a JSON listing.
4. Apply Shelter's compatibility policy and report the result. Separate "update available," "no update reported by this source," "outside the configured version series," and "unable to determine." Do not compare arbitrary version strings lexicographically or treat every vendor version as SemVer.
5. Display installed version, candidate version, provider, policy result, and any reason that blocks a decision. Do not invoke an upgrade command from the report workflow.

The Lite new-install targets of Node.js 24.x and Python 3.14.x do not by themselves establish an update policy for existing installations. Define that policy before enabling updates; initially display candidate updates and flag changes of version series separately. For uv-managed Python, Apple Git, or a version-manager installation that has no implemented update provider, show detected versions and an explicit unknown update status. Do not transfer ownership to Homebrew or WinGet to obtain an update.

Provider foundations: [Homebrew command reference](https://docs.brew.sh/Manpage) and [WinGet upgrade reference](https://learn.microsoft.com/en-us/windows/package-manager/winget/upgrade). Homebrew's `outdated` and WinGet's argument-free `upgrade` report candidates; upgrade application is a separate operation.

## Development and end-user distribution

Python executes Shelter code. uv manages Python versions, dependencies, environments, and development commands; it does not supply a desktop UI or automatically make an application self-contained. Electron is a desktop application framework using Chromium and Node.js. Neither Electron nor a GUI layer is required for this terminal CLI.

Developers will use Python and uv after `pyproject.toml` and dependencies are defined. Do not document `uv run shelter` as available until the entry point exists and is verified.

The end-user installation contract is independent: Shelter must be installable before user Python, uv, Homebrew, or WinGet exists. Evaluate an OS-specific bundle containing a private Python runtime; [PyInstaller](https://pyinstaller.org/en/stable/operating-mode.html) is a candidate, not an adopted or pinned dependency. Such bundles require builds and launch checks on each supported OS/architecture. A Python wheel or `uv tool install` alone does not satisfy the no-prerequisites contract.

The intended flow is the Shelter installer, then the installed `shelter` command, then `shelter lite` when initial setup is requested. Bundle the existing Lite scripts with the CLI so their installation behavior has one source. Keep current standalone Lite downloads working. Homebrew and WinGet registration can provide additional distribution paths later. Their presence is not required to print help or discover local tools.

## Implementation order and verification

1. Define the supported Python runtime and package metadata, derive the version from `VERSION`, and implement help/version with a verified local entry point.
2. Implement `status` with fixtures for missing managers, duplicate installations, aliases, and broken executables; do not change the real computer during tests.
3. Implement `outdated` with provider fixtures, policy decisions, timeouts, and source freshness reporting. Verify that report commands never call package installation or upgrade actions.
4. Add Lite delegation tests for OS selection, argument forwarding, process I/O, interruption, and exit codes, using a stub installer. Do not install tools in automated CLI tests.
5. Build self-contained artifacts, verify launch without external Python/uv/managers, and verify bundled Lite resources. Only then connect CLI installation and optional package-manager registration to release workflows.

This scaffold is validated through Python source parsing, local documentation links, and `git diff --check`. It adds no runnable CLI or behavior tests yet. Existing Lite implementations and release workflows are unchanged.

## References

- [uv documentation](https://docs.astral.sh/uv/)
- [Electron process model](https://www.electronjs.org/docs/latest/tutorial/process-model)
- [Technical specification](../specification.md)
- [Maintainer directory rules](../../CONTRIBUTING.md#adding-and-changing-directories)
