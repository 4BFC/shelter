# English Windows message and presentation SSOT for installation, builds and tests.
# ASCII source remains readable by Windows PowerShell 5.1 without a BOM.
$script:ShelterCopy = @{
    version = 'Shelter Lite {0}'
    logo_greeting = 'Hello, AI World'
    detail = '{0}'
    version_invalid = 'Could not read a valid Semantic Version from: {0}'
    unknown_option = 'Unknown option: {0}'
    invalid_color = '--color must be auto, always, or never.'
    conflicting_actions = '--check and --dry-run cannot be combined.'
    full_unavailable = 'The full version is not available yet. Use Lite instead.'
    invalid_mode = 'The supported mode is lite.'
    value_required = 'A value is required for {0}.'
    unsupported_platform = 'Use a native 64-bit Windows PowerShell 5.1 on Windows 11 x64. Windows Server, Windows 10, ARM64, and 32-bit processes are not supported.'
    elevated = 'Run Shelter as your regular user, without Run as administrator. Approve individual package UAC prompts when requested.'
    home_unknown = 'Could not determine the current user configuration directory.'
    platform_banner = 'Shelter Lite {0} - Windows {1} / x64'
    dry_run = 'Dry run'
    dry_run_intro = 'No actual installation or configuration changes will be made.'
    dry_run_complete = 'Dry run complete'
    dry_run_summary = 'Actual installations: 0, configuration changes: 0.'
    status_check = 'Status check'
    check_intro = 'Checking the current installation status only.'
    before_installation = 'Before installation'
    table_header = 'Tool | Current status | Planned action'
    check_complete = 'Check complete'
    check_required = 'Check required'
    check_complete_summary = 'All tools can run. No installation or configuration changes were made.'
    check_required_summary = 'Some tools are missing or failed to run. No installation or configuration changes were made.'
    planned_configuration = 'Planned configuration'
    configuration_plan = 'Append missing executable directories to your user PATH. Back up its current value first. PowerShell profiles, machine PATH, and execution policy are preserved.'
    bootstrap_warning = 'Missing WinGet will be prepared using Microsoft.WinGet.Client from PowerShell Gallery. Package installation may show administrator authentication prompts.'
    agreements = 'Setup accepts the WinGet source and package agreements for the fixed tool set.'
    blocked = 'Some tools fail to run, or Node.js/npm is only partially installed. Repair the existing installation first.'
    status_ready = 'Installed'
    status_missing = 'Not installed'
    status_partial = 'Partially installed'
    status_blocked = 'Check required'
    action_ready = 'Keep the existing installation'
    action_missing = 'Install new'
    action_partial = 'Install missing components'
    action_blocked = 'Repair the existing environment'
    command_failed = '{0} failed to run: {1}'
    python_lookup_failed = 'uv could not locate Python. Check the existing installation and access permissions.'
    native_failed = '{0} failed with exit code {1}. See the detailed log.'
    verification_failed = 'Installation or verification failed for {0}.'
    node_version_missing = 'No Node.js 24.x version was found in the WinGet source. No alternative major version will be installed.'
    terminal_invalid = 'Windows Terminal is registered, but its executable is missing.'
    installation_complete = 'Installation complete'
    installation_failed = 'Installation failed'
    setup_starting = 'Starting Shelter Lite setup.'
    tools_ready = 'Your development tools are ready.'
    setup_failed = 'Could not complete the installation.'
    no_rollback = 'Installation and configuration changes already made are not rolled back automatically.'
    retry = 'Check the detailed log, resolve the issue, then run the installer again.'
    log_path = 'Detailed log: {0}'
    restart = 'Reopen your terminal and editor to use the new executable paths.'
    paths_backup = 'User PATH backup: {0}'
    identity = 'Configure your Git identity and GitHub login separately.'
    nothing_to_install = 'No new tools need to be installed.'
    build_complete = 'Created: {0}'
    release_mismatch = 'Release tag {0} does not match expected tag {1} from VERSION.'
    preview = 'Message preview: {0} (no actual installation)'
    test_install = 'Installation workflow test: temporary environment only. No actual PC installation or configuration changes.'
    test_pass = 'PASS {0}'
    test_fail = 'FAIL {0}: {1}'
    test_summary = '{0} passed, {1} failed'
    finish = 'Press Return to finish. You can then close this window.'
    help = @'
Shelter Lite for Windows
Usage: powershell.exe -NoProfile -ExecutionPolicy Bypass -File install.ps1 [options]

  --dry-run              Preview the fixed setup without changes or downloads
  --check                Check installed tools only (0 ready, 1 needs attention)
  --version, -V          Print the product version
  --help, -h             Show this help
  --mode lite            Set up the complete fixed tool set (the default)
  --color [always|auto|never]  Default: always; --color alone forces colors

Windows 11 x64, native Windows PowerShell 5.1. Run without elevation.
Missing tools: WinGet, Git, VS Code, Windows Terminal, Node.js 24 + npm,
Python 3.14 + uv, and GitHub CLI. Working existing versions are preserved.
Exit codes: 0 success, 1 installation/check failure, 2 invalid option/platform.
ExecutionPolicy Bypass applies to this process only; managed policies still apply.
'@
}

function Get-ShelterText {
    param([string]$Key, [object[]]$Values = @())
    if (-not $script:ShelterCopy.ContainsKey($Key)) { throw "Unknown message key: $Key" }
    return [string]::Format([Globalization.CultureInfo]::InvariantCulture, $script:ShelterCopy[$Key], $Values)
}

function Get-ShelterColoredText {
    param([string]$Tone, [string]$Text)
    $mode = $script:ShelterColor
    $enabled = $mode -eq 'always' -or ($mode -eq 'auto' -and -not [Console]::IsOutputRedirected -and $env:TERM -ne 'dumb' -and -not $env:NO_COLOR)
    if (-not $enabled) { return $Text }
    $code = switch ($Tone) { success {32} warning {33} error {31} default {36} }
    return "$([char]27)[1;${code}m$Text$([char]27)[0m"
}

function Initialize-ShelterConsole {
    # Enable ANSI rendering for this console session, including Windows PowerShell
    # 5.1 in conhost. No persistent terminal setting or execution policy is changed.
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return }
    try {
        if (-not ('Shelter.ConsoleMode' -as [type])) {
            Add-Type @'
using System;
using System.Runtime.InteropServices;
namespace Shelter {
    public static class ConsoleMode {
        [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int id);
        [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr handle, out uint mode);
        [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr handle, uint mode);
    }
}
'@
        }
        $handle = [Shelter.ConsoleMode]::GetStdHandle(-11)
        $mode = [uint32]0
        if ([Shelter.ConsoleMode]::GetConsoleMode($handle,[ref]$mode)) {
            [void][Shelter.ConsoleMode]::SetConsoleMode($handle,($mode -bor 4))
        }
    } catch { } # Hosts without a console still receive the requested ANSI output.
}

function Write-ShelterMessage {
    param([string]$Tone, [string]$Key, [object[]]$Values = @())
    $prefix = if ($Tone -in @('success','warning','error')) { $Tone } else { 'note' }
    $dot = Get-ShelterColoredText $Tone ([string][char]0x25CF)
    Write-Host ('{0} {1}: {2}' -f $dot, $prefix, (Get-ShelterText $Key $Values))
}

function Write-ShelterSection {
    param([string]$Key, [string]$Tone = '')
    $icon = switch ($Key) {
        dry_run {0xF0C3} status_check {0xF002} before_installation {0xF0AE}
        planned_configuration {0xF013} installation_failed {0xF05C}
        check_required {0xF071} default {0xF00C}
    }
    $title = '{0} {1}' -f [char]$icon, (Get-ShelterText $Key)
    if ($Tone) { $title = Get-ShelterColoredText $Tone $title }
    Write-Host "`n$title"
}

function Write-ShelterLogo {
    Write-Host @'
  ____  _          _ _              _     _ _
 / ___|| |__   ___| | |_ ___ _ __  | |   (_) |_ ___
 \___ \| '_ \ / _ \ | __/ _ \ '__| | |   | | __/ _ \
  ___) | | | |  __/ | ||  __/ |    | |___| | ||  __/
 |____/|_| |_|\___|_|\__\___|_|    |_____|_|\__\___|
'@
    Write-Host (Get-ShelterText logo_greeting)
    Write-Host ''
}

$script:ShelterColor = 'always'
