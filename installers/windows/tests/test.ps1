# Dependency-free isolated tests. All package, platform, registry and log ACL
# operations are mocked. This suite never installs tools or edits user settings.
param(
    [ValidateSet('notification','warning','failure','success')][string]$Preview,
    [Alias('Intall')][ValidateSet('success','failure','dry-run')][string]$Install,
    [ValidateSet('always','auto','never')][string]$Color = 'always'
)
$ErrorActionPreference = 'Stop'
$installer = if ($env:SHELTER_TEST_INSTALLER) { $env:SHELTER_TEST_INSTALLER } else { Join-Path $PSScriptRoot '..\install.ps1' }
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..'))
$temp = Join-Path ([IO.Path]::GetTempPath()) ('shelter-tests-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($temp)
$originalPath = $env:Path

function Assert-True { param($Value,[string]$Message='Assertion failed'); if (-not $Value) { throw $Message } }
function Assert-Equal { param($Expected,$Actual); if ($Expected -cne $Actual) { throw "Expected <$Expected>, got <$Actual>" } }
function Invoke-CapturedMain {
    param([string[]]$Arguments)
    $lines = @(Invoke-ShelterMain -Arguments $Arguments 6>&1)
    $script:LastCode = [int]$lines[-1]
    return (($lines | Select-Object -SkipLast 1 | ForEach-Object { "$_" }) -join "`n")
}
function Set-MockEnvironment {
    $script:States = @{}; $script:Installed = @(); $script:Saved=$false
    $script:FailTool=''; $script:VerifyFailure=''; $script:ProbeCount=0
    foreach ($tool in $script:ShelterTools) { $script:States[$tool]='ready' }
    # Functions installed in script scope are reset from sources before each test.
    function script:Get-ShelterPlatform { return '10.0.26100' }
    function script:Get-ShelterToolProbe {
        param([string]$Tool)
        $script:ProbeCount++
        return (New-ShelterProbe $script:States[$Tool] -Version 'test version')
    }
    function script:Initialize-ShelterLog {
        $script:ShelterContext.Log = Join-Path $temp ('test-' + [guid]::NewGuid().ToString('N') + '.log')
        [IO.File]::WriteAllText($script:ShelterContext.Log,'')
    }
    function script:Install-ShelterTool {
        param([string]$Tool,$Before)
        $script:Installed += $Tool
        if ($Tool -eq $script:FailTool) { throw 'Simulated package failure' }
        if ($Tool -ne $script:VerifyFailure) { $script:States[$Tool]='ready' }
    }
    function script:Save-ShelterPaths { param($Probes); $script:Saved=$true }
}

$tests = [ordered]@{
    'version and help do not inspect the platform' = {
        function Get-ShelterPlatform { throw 'Must not inspect platform' }
        $output=Invoke-CapturedMain @('--version'); Assert-Equal 0 $script:LastCode
        Assert-Equal (Get-ShelterText version @($script:ShelterReleaseVersion)) $output
        $output=Invoke-CapturedMain @('--help'); Assert-Equal 0 $script:LastCode
        Assert-True ($output.Contains('--dry-run'))
        Assert-True (-not $output.Contains((Get-ShelterText logo_greeting)))
    }
    'invalid options return 2 without installation' = {
        foreach ($options in @(@('--unknown'),@('--mode','full'),@('--mode'),@('--color','invalid'),@('--check','--dry-run'))) {
            $null=Invoke-CapturedMain $options; Assert-Equal 2 $script:LastCode
        }
    }
    'color defaults and option values' = {
        Assert-Equal 'always' (Read-ShelterOptions @()).Color
        Assert-Equal 'always' (Read-ShelterOptions @('--color')).Color
        Assert-Equal 'auto' (Read-ShelterOptions @('--color','auto')).Color
        Assert-Equal 'never' (Read-ShelterOptions @('--color','never')).Color
        $output=Invoke-CapturedMain @('--color','never','--unknown')
        Assert-Equal 2 $script:LastCode; Assert-True (-not $output.Contains([string][char]27))
    }
    'unsupported platform exits before logs or probes' = {
        function Get-ShelterPlatform { throw 'Unsupported platform' }
        function Initialize-ShelterLog { throw 'Should not create a log' }
        $null=Invoke-CapturedMain @('--dry-run','--color','never'); Assert-Equal 2 $script:LastCode
    }
    'platform matrix accepts only native Windows 11 x64 clients' = {
        $script:PlatformInfo=@{ IsWindows=$true; Version='10.0.26100'; Build=26100; ProductType=1; Architecture='AMD64'; NativeArchitecture=9; ShellVersion=[version]'5.1'; ShellEdition='Desktop'; Emulated=$false; Elevated=$false }
        function Get-ShelterPlatformInfo { return $script:PlatformInfo }
        function Test-Path { return $true }
        $previous=$env:LOCALAPPDATA
        try {
            $env:LOCALAPPDATA=$temp
            Assert-Equal '10.0.26100' (Get-ShelterPlatform)
            foreach ($change in @(@('IsWindows',$false),@('ShellEdition','Core'),@('ShellVersion',[version]'4.0'),@('Build',19045),@('ProductType',3),@('NativeArchitecture',12),@('Architecture','ARM64'),@('Architecture','x86'),@('Emulated',$true))) {
                $key=$change[0];$old=$script:PlatformInfo[$key];$script:PlatformInfo[$key]=$change[1];$caught=$false
                try { $null=Get-ShelterPlatform } catch { $caught=$true }
                $script:PlatformInfo[$key]=$old; Assert-True $caught $key
            }
        } finally { $env:LOCALAPPDATA=$previous }
    }
    'elevated execution is rejected before user-scoped configuration' = {
        function Get-ShelterPlatformInfo { return @{ IsWindows=$true; Version='10.0.26100'; Build=26100; ProductType=1; Architecture='AMD64'; NativeArchitecture=9; ShellVersion=[version]'5.1'; ShellEdition='Desktop'; Emulated=$false; Elevated=$true } }
        $caught=$false
        try { $null=Get-ShelterPlatform } catch { $caught=$_.Exception.Message -ceq (Get-ShelterText elevated) }
        Assert-True $caught
    }
    'all four message states share the catalog and dot-only colors' = {
        foreach ($entry in @(@('note','setup_starting'),@('warning','restart'),@('error','setup_failed'),@('success','tools_ready'))) {
            $script:ShelterColor='always'
            $output=(Write-ShelterMessage $entry[0] $entry[1] 6>&1 | ForEach-Object { "$_" }) -join "`n"
            Assert-True ($output.Contains("$([char]27)[0m $($entry[0]):"))
            Assert-Equal 2 ([regex]::Matches($output,"$([char]27)\[").Count)
            $script:ShelterColor='never'
            $plain=(Write-ShelterMessage $entry[0] $entry[1] 6>&1 | ForEach-Object { "$_" }) -join "`n"
            Assert-True (-not $plain.Contains([string][char]27))
            Assert-True ($plain.Contains((Get-ShelterText $entry[1])))
        }
    }
    'forced colors override NO_COLOR and TERM while auto respects them' = {
        $oldNoColor=$env:NO_COLOR; $oldTerm=$env:TERM
        try {
            $env:NO_COLOR='1';$env:TERM='dumb';$script:ShelterColor='always'
            Assert-True ((Get-ShelterColoredText success 'x').Contains([string][char]27))
            $script:ShelterColor='auto'; Assert-Equal 'x' (Get-ShelterColoredText success 'x')
        } finally { $env:NO_COLOR=$oldNoColor;$env:TERM=$oldTerm }
    }
    'dry-run with missing tools performs no mutations' = {
        Set-MockEnvironment
        foreach ($tool in $script:ShelterTools) { $script:States[$tool]='missing' }
        function Initialize-ShelterLog { throw 'Dry-run must not create logs' }
        $output=Invoke-CapturedMain @('--dry-run','--color','never')
        Assert-Equal 0 $script:LastCode; Assert-Equal 0 $script:Installed.Count; Assert-True (-not $script:Saved)
        Assert-True ($output.Contains((Get-ShelterText bootstrap_warning)))
        Assert-True ($output.Contains((Get-ShelterText dry_run_summary)))
        Assert-Equal 1 ([regex]::Matches($output,[regex]::Escape('____  _')).Count)
        Assert-Equal 1 ([regex]::Matches($output,[regex]::Escape((Get-ShelterText logo_greeting))).Count)
    }
    'ready check succeeds and missing check returns 1 without changes' = {
        Set-MockEnvironment
        $output=Invoke-CapturedMain @('--check'); Assert-Equal 0 $script:LastCode
        Assert-True (-not $output.Contains((Get-ShelterText logo_greeting)))
        $script:States.git='missing'
        $null=Invoke-CapturedMain @('--check'); Assert-Equal 1 $script:LastCode
        Assert-Equal 0 $script:Installed.Count; Assert-True (-not $script:Saved)
        Assert-Equal '' $script:ShelterContext.Log
    }
    'working installations are preserved and setup is idempotent' = {
        Set-MockEnvironment
        $output=Invoke-CapturedMain @('--color','never'); Assert-Equal 0 $script:LastCode
        Assert-Equal 0 $script:Installed.Count; Assert-True $script:Saved
        Assert-True ($output.Contains((Get-ShelterText tools_ready)))
        Assert-Equal 1 ([regex]::Matches($output,[regex]::Escape((Get-ShelterText logo_greeting))).Count)
        Assert-True (-not $output.Contains((Get-ShelterText no_rollback)))
    }
    'missing tools install in dependency order and a rerun preserves them' = {
        Set-MockEnvironment
        foreach ($tool in $script:ShelterTools) { $script:States[$tool]='missing' }
        $null=Invoke-CapturedMain @(); Assert-Equal 0 $script:LastCode
        Assert-Equal ($script:ShelterTools -join ',') ($script:Installed -join ',')
        $script:Installed=@(); $null=Invoke-CapturedMain @(); Assert-Equal 0 $script:LastCode
        Assert-Equal 0 $script:Installed.Count
    }
    'blocked preflight makes no package or PATH changes' = {
        Set-MockEnvironment; $script:States.node='blocked'; $script:States.git='missing'
        $output=Invoke-CapturedMain @('--color','never'); Assert-Equal 1 $script:LastCode
        Assert-Equal 0 $script:Installed.Count; Assert-True (-not $script:Saved)
        Assert-True (-not $output.Contains((Get-ShelterText no_rollback)))
    }
    'package failure stops subsequent work and keeps earlier installations' = {
        Set-MockEnvironment
        foreach ($tool in @('git','vscode','gh')) { $script:States[$tool]='missing' }
        $script:FailTool='vscode'
        $output=Invoke-CapturedMain @('--color','never'); Assert-Equal 1 $script:LastCode
        Assert-Equal 'git,vscode' ($script:Installed -join ','); Assert-Equal 'ready' $script:States.git
        Assert-True (-not $script:Saved); Assert-True ($output.Contains((Get-ShelterText no_rollback)))
    }
    'post-install verification failure stops setup' = {
        Set-MockEnvironment; $script:States.git='missing'; $script:VerifyFailure='git'
        $null=Invoke-CapturedMain @(); Assert-Equal 1 $script:LastCode
        Assert-True (-not $script:Saved)
    }
    'log creation failure happens before package changes' = {
        Set-MockEnvironment
        function Initialize-ShelterLog { throw 'Cannot create log' }
        $null=Invoke-CapturedMain @(); Assert-Equal 1 $script:LastCode
        Assert-Equal 0 $script:Installed.Count; Assert-True (-not $script:Saved)
    }
    'partial Node is blocked and partial Python is allowed' = {
        function Get-ShelterCommandProbe {
            param($Name,$Candidates,[switch]$Python)
            if ($Name -eq 'npm.cmd') { return (New-ShelterProbe missing) }
            return (New-ShelterProbe ready -Version 'existing' -Path (Join-Path $temp 'tool.exe'))
        }
        Assert-Equal 'blocked' (Get-ShelterToolProbe node).State
        function Get-ShelterPythonProbe { return (New-ShelterProbe missing) }
        Assert-Equal 'partial' (Get-ShelterToolProbe python).State
    }
    'broken command is not treated as absent' = {
        function Resolve-ShelterExecutable { return 'broken.exe' }
        function Invoke-ShelterNative { return @{ Code=1; Output='broken' } }
        Assert-Equal 'blocked' (Get-ShelterCommandProbe git.exe).State
    }
    'Python aliases are skipped without invoking the Store' = {
        function Get-Command { return [pscustomobject]@{ Source='C:\Users\Example\AppData\Local\Microsoft\WindowsApps\python.exe' } }
        function Test-Path { return $true }
        Assert-Equal '' (Resolve-ShelterExecutable python.exe -SkipWindowsAlias)
    }
    'Python find and list probes are offline and lookup failures block' = {
        function Get-ShelterCommandProbe {
            param($Name,$Candidates,[switch]$Python)
            if ($Name -eq 'uv.exe') { return (New-ShelterProbe ready -Path 'uv.exe') }
            return (New-ShelterProbe missing)
        }
        function Invoke-ShelterNative {
            param($File,$Arguments)
            foreach ($flag in @('--offline','--no-cache','--no-config','--no-python-downloads')) { Assert-True ($flag -in $Arguments) }
            return @{ Code=1; Output='lookup error' }
        }
        Assert-Equal 'blocked' (Get-ShelterPythonProbe).State
    }
    'empty installed Python list establishes absence' = {
        function Get-ShelterCommandProbe {
            param($Name,$Candidates,[switch]$Python)
            if ($Name -eq 'uv.exe') { return (New-ShelterProbe ready -Path 'uv.exe') }
            return (New-ShelterProbe missing)
        }
        function Invoke-ShelterNative {
            param($File,$Arguments)
            if ('list' -in $Arguments) { return @{ Code=0; Output='' } }
            return @{ Code=1; Output='' }
        }
        Assert-Equal 'missing' (Get-ShelterPythonProbe).State
    }
    'managed Python exposes the versioned bin directory while retaining aliases' = {
        $script:PythonFile=Join-Path $temp 'managed-python.exe'
        $script:PythonBin=Join-Path $temp 'versioned-python-bin'
        [IO.File]::WriteAllText($script:PythonFile,'test executable')
        [void][IO.Directory]::CreateDirectory($script:PythonBin)
        function Get-ShelterCommandProbe {
            param($Name,$Candidates,[switch]$Python)
            if ($Name -eq 'python.exe') { return (New-ShelterProbe missing) }
            return (New-ShelterProbe ready -Version 'test' -Path $Name)
        }
        function Invoke-ShelterNative {
            param($File,$Arguments)
            Assert-True ('--offline' -in $Arguments)
            if ('find' -in $Arguments) { return @{ Code=0; Output=$script:PythonFile } }
            Assert-True ('--bin' -in $Arguments)
            return @{ Code=0; Output=$script:PythonBin }
        }
        $probe=Get-ShelterPythonProbe
        Assert-Equal 'ready' $probe.State; Assert-Equal $script:PythonBin $probe.ExtraPaths[0]
    }
    'VS Code detection does not confuse Cursor code.cmd' = {
        function Resolve-ShelterExecutable { return (Join-Path $temp 'Cursor\bin\code.cmd') }
        function Test-Path { return $false }
        Assert-Equal 'missing' (Get-ShelterToolProbe vscode).State
    }
    'Terminal detection checks package executable without launching a GUI' = {
        function Get-AppxPackage { return [pscustomobject]@{ Version='1.24.1.0'; InstallLocation=$temp } }
        function Test-Path { return $true }
        function Invoke-ShelterNative { throw 'Must not launch Terminal' }
        Assert-Equal 'ready' (Get-ShelterTerminalProbe).State
        function Test-Path { return $false }
        Assert-Equal 'blocked' (Get-ShelterTerminalProbe).State
    }
    'Node lookup selects the highest 24.x and never installs another major' = {
        function Get-ShelterToolProbe { return (New-ShelterProbe ready -Path 'winget.exe') }
        function Invoke-ShelterNative { return @{ Code=0; Output="26.1.0`n24.9.0`n24.22.1`n22.0.0" } }
        function Install-ShelterPackage { param($Id,$Extra); Assert-Equal 'OpenJS.NodeJS.LTS' $Id; Assert-Equal '--version,24.22.1' ($Extra -join ',') }
        $script:ShelterContext=@{ Log='' }; Install-ShelterTool node (New-ShelterProbe missing)
        function Invoke-ShelterNative { return @{ Code=0; Output='26.1.0' } }
        $caught=$false; try { Install-ShelterTool node (New-ShelterProbe missing) } catch { $caught=$true }
        Assert-True $caught
    }
    'WinGet invocation uses exact source, no-upgrade and agreements' = {
        function Get-ShelterToolProbe { return (New-ShelterProbe ready -Path 'winget.exe') }
        function Update-ShelterProcessPath { }
        function Invoke-ShelterNative {
            param($File,$Arguments)
            foreach ($flag in @('--exact','--source','winget','--no-upgrade','--silent','--accept-package-agreements','--accept-source-agreements','--disable-interactivity')) { Assert-True ($flag -in $Arguments) }
            return @{ Code=0; Output='installed' }
        }
        $script:ShelterContext=@{ Log='' }; Install-ShelterPackage Git.Git
    }
    'WinGet bootstrap uses current-user Microsoft repair and restores TLS settings' = {
        $script:BootstrapCalls=@(); $previous=[Net.ServicePointManager]::SecurityProtocol
        function Install-PackageProvider {
            param($Name,$MinimumVersion,$Scope,[switch]$Force,$Confirm,$ErrorAction)
            Assert-Equal 'NuGet' $Name; Assert-Equal 'CurrentUser' $Scope
            $script:BootstrapCalls+='provider'
        }
        function Install-Module {
            param($Name,$Scope,$Repository,[switch]$Force,[switch]$AllowClobber,$Confirm,$ErrorAction)
            Assert-Equal 'Microsoft.WinGet.Client' $Name; Assert-Equal 'CurrentUser' $Scope; Assert-Equal 'PSGallery' $Repository
            $script:BootstrapCalls+='module'
        }
        function Import-Module { param($Name,$ErrorAction); Assert-Equal 'Microsoft.WinGet.Client' $Name }
        function Repair-WinGetPackageManager { param([switch]$Force,[switch]$Latest,$ErrorAction); Assert-True $Latest; $script:BootstrapCalls+='repair' }
        function Update-ShelterProcessPath { $script:BootstrapCalls+='refresh' }
        Install-ShelterWinGet
        Assert-Equal 'provider,module,repair,refresh' ($script:BootstrapCalls -join ',')
        Assert-Equal $previous ([Net.ServicePointManager]::SecurityProtocol)
    }
    'native wrapper preserves output and nonzero exit codes' = {
        $hostPath = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $result = Invoke-ShelterNative $hostPath @('-NoProfile','-Command',"[Console]::WriteLine('native output'); exit 7")
        Assert-Equal 7 $result.Code; Assert-True ($result.Output.Contains('native output'))
    }
    'failed WinGet install does not refresh paths' = {
        function Get-ShelterToolProbe { return (New-ShelterProbe ready -Path 'winget.exe') }
        function Invoke-ShelterNative { return @{ Code=3010; Output='Restart required' } }
        function Update-ShelterProcessPath { throw 'Must not refresh after failure' }
        $script:ShelterContext=@{ Log='' }; $caught=$false
        try { Install-ShelterPackage Git.Git } catch { $caught=$_.Exception.Message.Contains('3010') }
        Assert-True $caught
    }
    'Python setup installs only missing components' = {
        $script:Calls=@()
        function Install-ShelterPackage { param($Id); $script:Calls += $Id }
        function Get-ShelterCommandProbe { return (New-ShelterProbe ready -Path 'uv.exe') }
        function Invoke-ShelterNative { param($File,$Arguments); $script:Calls += ($Arguments -join ' '); return @{ Code=0; Output='Python 3.14' } }
        function Update-ShelterProcessPath { }
        $script:ShelterContext=@{ Log='' }
        Install-ShelterTool python (New-ShelterProbe partial -Parts @((New-ShelterProbe ready),(New-ShelterProbe missing)))
        Assert-Equal 'astral-sh.uv' ($script:Calls -join ',')
        $script:Calls=@()
        Install-ShelterTool python (New-ShelterProbe partial -Parts @((New-ShelterProbe missing),(New-ShelterProbe ready)))
        Assert-Equal '--no-config python install 3.14' ($script:Calls -join ',')
    }
    'PATH backups preserve raw entries and reruns do not duplicate paths' = {
        $script:Stored='%USERPROFILE%\custom;C:\keep'; $script:Writes=0
        function Get-ShelterStoredPath { return $script:Stored }
        function Set-ShelterStoredPath { param($Value); $script:Stored=$Value; $script:Writes++ }
        function Set-Acl { param($LiteralPath,$AclObject,$ErrorAction) }
        function Get-Acl { param($LiteralPath); return 'test ACL' }
        $script:ShelterContext=@{ Log=(Join-Path $temp 'paths.log'); Changed=$false }
        [IO.File]::WriteAllText($script:ShelterContext.Log,'')
        $path = Join-Path $temp 'new tools'
        $probes=@(New-ShelterProbe ready -Path (Join-Path $path 'git.exe'))
        Save-ShelterPaths $probes
        Assert-Equal ('%USERPROFILE%\custom;C:\keep;'+$path) $script:Stored
        $backup=Get-Content -LiteralPath ($script:ShelterContext.Log+'.path-backup.json') -Raw | ConvertFrom-Json
        Assert-Equal '%USERPROFILE%\custom;C:\keep' $backup.Path
        Save-ShelterPaths $probes; Assert-Equal 1 $script:Writes
    }
    'PATH backup protection failure prevents registry changes' = {
        function Get-ShelterStoredPath { return 'existing' }
        function Set-ShelterStoredPath { throw 'Registry must not be changed' }
        function Get-Acl { return 'test ACL' }
        function Set-Acl { throw 'Cannot protect backup' }
        $script:ShelterContext=@{ Log=(Join-Path $temp 'backup-failure.log'); Changed=$false }
        [IO.File]::WriteAllText($script:ShelterContext.Log,'')
        $caught=$false
        try { Save-ShelterPaths @((New-ShelterProbe ready -Path (Join-Path $temp 'new-tool.exe'))) }
        catch { $caught=$_.Exception.Message -eq 'Cannot protect backup' }
        Assert-True $caught; Assert-True (-not $script:ShelterContext.Changed)
    }
    'logs remove ANSI sequences' = {
        $script:ShelterContext=@{ Log=(Join-Path $temp 'ansi.log') }
        Add-ShelterLog "$([char]27)[31mplain$([char]27)[0m"
        Assert-True (-not ([IO.File]::ReadAllText($script:ShelterContext.Log).Contains([string][char]27)))
    }
    'SemVer rejects invalid metadata and accepts prereleases' = {
        foreach ($value in @('0.2.0','1.0.0-rc.1','1.2.3+build.01','1.0.0-a-1')) { Assert-True (Test-ShelterVersion $value) $value }
        foreach ($value in @('v0.2.0','01.2.3','1.2','1.0.0-01','1.0.0+','1.0.0`n','1.0.0.1')) { Assert-True (-not (Test-ShelterVersion $value)) $value }
        $versionFile=Join-Path $temp 'VERSION'
        [IO.File]::WriteAllText($versionFile,"0.2.0`n")
        Assert-Equal '0.2.0' (Read-ShelterVersion $versionFile)
        [IO.File]::WriteAllText($versionFile,"0.2.0`r`n")
        Assert-Equal '0.2.0' (Read-ShelterVersion $versionFile)
        [IO.File]::WriteAllText($versionFile,' 0.2.0 ')
        $caught=$false; try { $null=Read-ShelterVersion $versionFile } catch { $caught=$true }
        Assert-True $caught
    }
    'packaging verifies BOM, license, checksums, relocation and reproducibility' = {
        $out=Join-Path $temp 'bundle with spaces'
        & (Join-Path $root 'installers/windows/build.ps1') -OutputDirectory $out
        $archive=Join-Path $out 'shelter-lite-windows.zip'
        $hash=(Get-FileHash -LiteralPath $archive).Hash
        & (Join-Path $root 'installers/windows/build.ps1') -OutputDirectory $out
        Assert-Equal $hash (Get-FileHash -LiteralPath $archive).Hash
        foreach ($name in @('shelter-lite-windows.zip','shelter-lite-windows.ps1')) {
            $expected=([IO.File]::ReadAllText((Join-Path $out ($name+'.sha256'))) -split ' ')[0]
            Assert-Equal $expected (Get-FileHash -LiteralPath (Join-Path $out $name)).Hash.ToLowerInvariant()
        }
        $bundle=Join-Path $out 'shelter-lite-windows.ps1'
        $bytes=[IO.File]::ReadAllBytes($bundle); Assert-Equal '239,187,191' ($bytes[0..2] -join ',')
        Assert-True ([IO.File]::ReadAllText($bundle).Contains('MIT License'))
        $unpack=Join-Path $temp 'unpacked'; Expand-Archive -LiteralPath $archive -DestinationPath $unpack
        Assert-Equal 3 @(Get-ChildItem -LiteralPath $unpack).Count
        Assert-Equal ([IO.File]::ReadAllText((Join-Path $root 'VERSION')).Trim()) ([IO.File]::ReadAllText((Join-Path $unpack 'VERSION')).Trim())
        . $bundle
        $output=Invoke-CapturedMain @('--version'); Assert-Equal 0 $script:LastCode
        Assert-Equal (Get-ShelterText version @($script:ShelterReleaseVersion)) $output
        $launcher=[IO.File]::ReadAllText((Join-Path $unpack 'Shelter Lite.cmd'))
        Assert-True ($launcher.Contains('exit /b %SHELTER_EXIT%'))
        Assert-True ($launcher.Contains('-NoProfile -ExecutionPolicy Bypass'))
    }
}

try {
    . $installer
    $script:ShelterColor=$Color
    if ($Preview -and $Install) { throw 'Choose Preview or Install.' }
    if ($Preview) {
        Write-Host (Get-ShelterText preview @($Preview))
        switch ($Preview) {
            notification { Write-ShelterMessage note setup_starting }
            warning { Write-ShelterMessage warning restart }
            failure { Write-ShelterSection installation_failed error; Write-ShelterMessage error setup_failed }
            success { Write-ShelterSection installation_complete success; Write-ShelterMessage success tools_ready }
        }
        exit 0
    }
    if ($Install) {
        Write-Host (Get-ShelterText test_install)
        Set-MockEnvironment
        $script:States.git='missing'; $script:States.gh='missing'
        $arguments=@('--color',$Color)
        if ($Install -eq 'failure') { $script:FailTool='git' }
        if ($Install -eq 'dry-run') { $arguments+='--dry-run' }
        $code=Invoke-ShelterMain $arguments
        $expected=if ($Install -eq 'failure') {1} else {0}
        Assert-Equal $expected $code
        exit 0
    }
    $passed=0; $failed=0
    foreach ($name in $tests.Keys) {
        . $installer
        try {
            & $tests[$name]
            $passed++; Write-Host (Get-ShelterText test_pass @($name))
        } catch {
            $failed++; Write-Host (Get-ShelterText test_fail @($name,$_.Exception.Message))
            Write-Host $_.ScriptStackTrace
        }
    }
    Write-Host (Get-ShelterText test_summary @($passed,$failed))
    if ($failed -gt 0) { exit 1 }
    exit 0
} finally {
    $env:Path=$originalPath
    Remove-Item -LiteralPath $temp -Recurse -Force
}
