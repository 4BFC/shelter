# Native operations are kept in small functions so tests never install packages.
function New-ShelterProbe {
    param([string]$State, [string]$Version = '', [string]$Path = '', [string]$Detail = '', [object[]]$Parts = @(), [string[]]$ExtraPaths = @())
    [pscustomobject]@{ State=$State; Version=$Version; Path=$Path; Detail=$Detail; Parts=$Parts; ExtraPaths=$ExtraPaths }
}

function Get-ShelterPlatformInfo {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { return @{ IsWindows=$false } }
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return @{
        IsWindows=$true; Version=$os.Version; Build=[int]$os.BuildNumber; ProductType=$os.ProductType
        Architecture=$env:PROCESSOR_ARCHITECTURE; Emulated=[bool]$env:PROCESSOR_ARCHITEW6432
        NativeArchitecture=[int]$cpu.Architecture
        ShellVersion=$PSVersionTable.PSVersion; ShellEdition=$PSVersionTable.PSEdition
        Elevated=$principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
}

function Get-ShelterPlatform {
    $info = Get-ShelterPlatformInfo
    if (-not $info.IsWindows -or $info.ShellEdition -ne 'Desktop' -or $info.ShellVersion -lt [version]'5.1' -or $info.ProductType -ne 1 -or $info.Build -lt 22000 -or
        $info.NativeArchitecture -ne 9 -or $info.Architecture -ne 'AMD64' -or $info.Emulated) { throw (Get-ShelterText unsupported_platform) }
    if ($info.Elevated) { throw (Get-ShelterText elevated) }
    if (-not $env:LOCALAPPDATA -or -not (Test-Path -LiteralPath $env:LOCALAPPDATA -PathType Container)) { throw (Get-ShelterText home_unknown) }
    return $info.Version
}

function Add-ShelterLog {
    param([string]$Text)
    if ($script:ShelterContext.Log) {
        $plain = [regex]::Replace($Text, "$([char]27)\[[0-9;?]*[A-Za-z]", '')
        [IO.File]::AppendAllText($script:ShelterContext.Log, $plain + [Environment]::NewLine)
    }
}

function Invoke-ShelterNative {
    param([string]$File, [string[]]$Arguments)
    $previous = $ErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $File @Arguments 2>&1 | ForEach-Object { "$_" }) -join "`n"
        $code = $LASTEXITCODE
        return [pscustomobject]@{ Code=$code; Output=$output.Trim() }
    } catch { return [pscustomobject]@{ Code=1; Output=$_.Exception.Message } }
    finally { $ErrorActionPreference = $previous }
}

function Resolve-ShelterExecutable {
    param([string]$Name, [string[]]$Candidates = @(), [switch]$SkipWindowsAlias)
    $commands = @(Get-Command $Name -All -CommandType Application -ErrorAction SilentlyContinue)
    $paths = @($commands | ForEach-Object { $_.Source }) + $Candidates
    foreach ($path in $paths) {
        if (-not $path) { continue }
        # Store Python aliases can launch the Store and are not installed Python.
        if ($SkipWindowsAlias -and $path -match '[\\/]Microsoft[\\/]WindowsApps[\\/]python[0-9.]*\.exe$') { continue }
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    return ''
}

function Get-ShelterCommandProbe {
    param([string]$Name, [string[]]$Candidates = @(), [switch]$Python)
    if ($Name -eq 'uv.exe') {
        $Candidates += @("$env:LOCALAPPDATA\Microsoft\WinGet\Links\uv.exe","$env:USERPROFILE\.local\bin\uv.exe","$env:ProgramFiles\WinGet\Links\uv.exe")
    }
    $path = Resolve-ShelterExecutable $Name $Candidates -SkipWindowsAlias:$Python
    if (-not $path) { return (New-ShelterProbe missing) }
    $result = Invoke-ShelterNative $path @('--version')
    if ($result.Code -ne 0 -or -not $result.Output) {
        return (New-ShelterProbe blocked -Path $path -Detail (Get-ShelterText command_failed @($Name,$result.Output)))
    }
    return (New-ShelterProbe ready -Version ($result.Output -split "`r?`n")[0] -Path $path)
}

function Get-ShelterTerminalProbe {
    $packages = @(Get-AppxPackage -Name Microsoft.WindowsTerminal -ErrorAction Stop)
    if ($packages.Count -eq 0) { return (New-ShelterProbe missing) }
    $package = $packages | Sort-Object Version -Descending | Select-Object -First 1
    $path = Join-Path $package.InstallLocation 'WindowsTerminal.exe'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return (New-ShelterProbe blocked -Detail (Get-ShelterText terminal_invalid))
    }
    # wt.exe has no supported --version probe; avoid opening a GUI during checks.
    return (New-ShelterProbe ready -Version ([string]$package.Version))
}

function Get-ShelterPythonProbe {
    $python = Get-ShelterCommandProbe python.exe -Python
    if ($python.State -ne 'missing') { return $python }
    $uv = Get-ShelterCommandProbe uv.exe
    if ($uv.State -eq 'ready') {
        $options = @('--no-cache','--no-config','--offline','python')
        $found = Invoke-ShelterNative $uv.Path ($options + @('find','--managed-python','--no-python-downloads'))
        if ($found.Code -eq 0 -and (Test-Path -LiteralPath $found.Output -PathType Leaf)) {
            $probe = Get-ShelterCommandProbe $found.Output -Python
            $bin = Invoke-ShelterNative $uv.Path ($options + @('dir','--bin'))
            if ($bin.Code -eq 0 -and (Test-Path -LiteralPath $bin.Output -PathType Container)) {
                # Expose uv's versioned python3.14.exe while preserving Store aliases
                # and existing version-manager precedence for unversioned python.
                $probe.ExtraPaths = @($bin.Output)
            }
            return $probe
        }
        $list = Invoke-ShelterNative $uv.Path ($options + @('list','--only-installed','--managed-python','--no-python-downloads'))
        if ($list.Code -ne 0 -or $list.Output) {
            return (New-ShelterProbe blocked -Detail (Get-ShelterText python_lookup_failed))
        }
    }
    return $python
}

function Get-ShelterToolProbe {
    param([string]$Tool)
    $local = $env:LOCALAPPDATA
    $programs = $env:ProgramFiles
    switch ($Tool) {
        winget { return (Get-ShelterCommandProbe winget.exe @("$local\Microsoft\WindowsApps\winget.exe")) }
        git { return (Get-ShelterCommandProbe git.exe @("$programs\Git\cmd\git.exe","$local\Programs\Git\cmd\git.exe")) }
        gh { return (Get-ShelterCommandProbe gh.exe @("$programs\GitHub CLI\gh.exe","$local\Programs\GitHub CLI\gh.exe")) }
        terminal { return (Get-ShelterTerminalProbe) }
        vscode {
            $paths = @("$local\Programs\Microsoft VS Code\bin\code.cmd","$programs\Microsoft VS Code\bin\code.cmd")
            $command = Resolve-ShelterExecutable code.cmd
            if ($command) { $paths = @($command) + $paths }
            foreach ($path in $paths) {
                $app = Join-Path (Split-Path (Split-Path $path)) 'Code.exe'
                if ((Test-Path -LiteralPath $path -PathType Leaf) -and (Test-Path -LiteralPath $app -PathType Leaf)) {
                    return (Get-ShelterCommandProbe $path)
                }
            }
            return (New-ShelterProbe missing)
        }
        node {
            $first = Get-ShelterCommandProbe node.exe @("$programs\nodejs\node.exe","$local\Programs\nodejs\node.exe")
            $npmCandidates = @()
            if ($first.Path) { $npmCandidates = @(Join-Path (Split-Path $first.Path) 'npm.cmd') }
            $second = Get-ShelterCommandProbe npm.cmd $npmCandidates
        }
        python {
            $first = Get-ShelterPythonProbe
            $second = Get-ShelterCommandProbe uv.exe
        }
        default { throw "Unknown tool: $Tool" }
    }
    $state = if ($first.State -eq 'blocked' -or $second.State -eq 'blocked') { 'blocked' }
        elseif ($first.State -eq 'ready' -and $second.State -eq 'ready') { 'ready' }
        elseif ($first.State -eq 'missing' -and $second.State -eq 'missing') { 'missing' }
        elseif ($Tool -eq 'node') { 'blocked' } else { 'partial' }
    return (New-ShelterProbe $state -Version ($first.Version + ' / ' + $second.Version) -Parts @($first,$second) -Detail (($first.Detail,$second.Detail | Where-Object { $_ }) -join '; '))
}

function Get-ShelterStoredPath {
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment')
    try {
        if ($null -eq $key) { return $null }
        return $key.GetValue('Path',$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    } finally { if ($key) { $key.Dispose() } }
}

function Set-ShelterStoredPath {
    param([string]$Value)
    $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey('Environment')
    try {
        $kind = if ('Path' -in $key.GetValueNames()) { $key.GetValueKind('Path') } else { [Microsoft.Win32.RegistryValueKind]::ExpandString }
        $key.SetValue('Path',$Value,$kind)
    } finally { $key.Dispose() }
    # New processes refresh their environment at login or after this notification.
    if (-not ('Shelter.EnvironmentBroadcast' -as [type])) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
namespace Shelter {
    public static class EnvironmentBroadcast {
        [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
        public static extern IntPtr SendMessageTimeout(IntPtr hwnd, uint msg, UIntPtr wparam, string text, uint flags, uint timeout, out UIntPtr result);
    }
}
'@
    }
    $result = [UIntPtr]::Zero
    [void][Shelter.EnvironmentBroadcast]::SendMessageTimeout([IntPtr]0xffff,0x1a,[UIntPtr]::Zero,'Environment',2,5000,[ref]$result)
}

function Update-ShelterProcessPath {
    # Retain current command/version-manager precedence; append new package paths.
    foreach ($scope in @('Machine','User')) {
        foreach ($directory in ([Environment]::GetEnvironmentVariable('Path',$scope) -split ';')) {
            if ($directory -and $directory -notin ($env:Path -split ';')) { $env:Path += ';' + [Environment]::ExpandEnvironmentVariables($directory) }
        }
    }
}

function Initialize-ShelterLog {
    $directory = Join-Path $env:LOCALAPPDATA 'Shelter\logs'
    [void][IO.Directory]::CreateDirectory($directory)
    $path = Join-Path $directory ('install-' + [guid]::NewGuid().ToString('N') + '.log')
    # Restrict to this user and SYSTEM; do not inherit broader parent permissions.
    $security = New-Object Security.AccessControl.FileSecurity
    $security.SetAccessRuleProtection($true,$false)
    foreach ($sid in @([Security.Principal.WindowsIdentity]::GetCurrent().User, (New-Object Security.Principal.SecurityIdentifier('S-1-5-18')))) {
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($sid,'FullControl','Allow')
        $security.AddAccessRule($rule)
    }
    $stream = [IO.File]::Create($path); $stream.Dispose()
    Set-Acl -LiteralPath $path -AclObject $security -ErrorAction Stop
    $script:ShelterContext.Log = $path
    Add-ShelterLog (Get-ShelterText version @($script:ShelterReleaseVersion))
}

function Save-ShelterPaths {
    param([object[]]$Probes)
    $directories = @()
    foreach ($probe in $Probes) {
        foreach ($part in @($probe) + @($probe.Parts)) {
            if ($part.Path -and $part.State -eq 'ready') { $directories += Split-Path $part.Path }
            if ($part.State -eq 'ready') { $directories += @($part.ExtraPaths) }
        }
    }
    $stored = Get-ShelterStoredPath
    $machine = [Environment]::GetEnvironmentVariable('Path','Machine')
    $known = @(($stored + ';' + $machine) -split ';' | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') })
    $missing = @($directories | Select-Object -Unique | Where-Object { $_.TrimEnd('\') -notin $known })
    if ($missing.Count -eq 0) { return }
    $backup = $script:ShelterContext.Log + '.path-backup.json'
    $record = @{ Path=$stored; WasAbsent=($null -eq $stored); CreatedUtc=[DateTime]::UtcNow.ToString('o') } | ConvertTo-Json
    # The backup inherits the log's explicit user-only ACL before data is written.
    [IO.File]::WriteAllText($backup,'')
    Set-Acl -LiteralPath $backup -AclObject (Get-Acl -LiteralPath $script:ShelterContext.Log) -ErrorAction Stop
    [IO.File]::WriteAllText($backup,$record)
    Add-ShelterLog (Get-ShelterText paths_backup @($backup))
    $script:ShelterContext.Changed = $true
    $separator = if ([string]::IsNullOrEmpty($stored) -or $stored.EndsWith(';')) { '' } else { ';' }
    Set-ShelterStoredPath ($stored + $separator + ($missing -join ';'))
}

function Install-ShelterWinGet {
    # Microsoft's current-user repair path; no Store browsing or global policy edit.
    $previous = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $previous -bor [Net.SecurityProtocolType]::Tls12
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -Confirm:$false -ErrorAction Stop
        Import-Module Microsoft.WinGet.Client -ErrorAction Stop
        Repair-WinGetPackageManager -Force -Latest -ErrorAction Stop | Out-Null
    } finally { [Net.ServicePointManager]::SecurityProtocol = $previous }
    Update-ShelterProcessPath
}

function Install-ShelterPackage {
    param([string]$Id, [string[]]$Extra = @())
    $winget = Get-ShelterToolProbe winget
    if ($winget.State -ne 'ready') { throw (Get-ShelterText verification_failed @('WinGet')) }
    $arguments = @('install','--id',$Id,'--exact','--source','winget','--no-upgrade','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity') + $Extra
    $result = Invoke-ShelterNative $winget.Path $arguments
    Add-ShelterLog ($Id + "`n" + $result.Output)
    # A reboot-required result is not success; leave it visible for the next retry.
    if ($result.Code -ne 0) { throw (Get-ShelterText native_failed @($Id,$result.Code)) }
    Update-ShelterProcessPath
}

function Install-ShelterTool {
    param([string]$Tool, $Before)
    switch ($Tool) {
        winget { Install-ShelterWinGet }
        git { Install-ShelterPackage Git.Git }
        vscode { Install-ShelterPackage Microsoft.VisualStudioCode @('--scope','user') }
        terminal { Install-ShelterPackage Microsoft.WindowsTerminal }
        gh { Install-ShelterPackage GitHub.cli }
        node {
            $winget = Get-ShelterToolProbe winget
            $result = Invoke-ShelterNative $winget.Path @('show','--id','OpenJS.NodeJS.LTS','--exact','--source','winget','--versions','--accept-source-agreements','--disable-interactivity')
            Add-ShelterLog $result.Output
            if ($result.Code -ne 0) { throw (Get-ShelterText native_failed @('WinGet Node.js version lookup',$result.Code)) }
            $versions = @([regex]::Matches($result.Output,'(?m)^\s*(24\.[0-9]+\.[0-9]+)\s*$') | ForEach-Object { [version]$_.Groups[1].Value } | Sort-Object -Descending)
            if ($versions.Count -eq 0) { throw (Get-ShelterText node_version_missing) }
            Install-ShelterPackage OpenJS.NodeJS.LTS @('--version',[string]$versions[0])
        }
        python {
            if ($Before.Parts[1].State -ne 'ready') { Install-ShelterPackage astral-sh.uv }
            if ($Before.Parts[0].State -ne 'ready') {
                $uv = Get-ShelterCommandProbe uv.exe
                $result = Invoke-ShelterNative $uv.Path @('--no-config','python','install','3.14')
                Add-ShelterLog $result.Output
                if ($result.Code -ne 0) { throw (Get-ShelterText native_failed @('uv Python installation',$result.Code)) }
                Update-ShelterProcessPath
            }
        }
    }
}

$script:ShelterTools = @('winget','git','vscode','terminal','node','python','gh')
$script:ShelterToolNames = @{ winget='WinGet'; git='Git'; vscode='VS Code'; terminal='Windows Terminal'; node='Node.js + npm'; python='Python + uv'; gh='GitHub CLI' }
