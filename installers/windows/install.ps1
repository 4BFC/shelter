# Windows PowerShell 5.1 compatible entry point. No installation when dot-sourced.
# BEGIN SHELTER SOURCE IMPORTS
. (Join-Path $PSScriptRoot 'messages.ps1')
. (Join-Path $PSScriptRoot '..\..\scripts\version.ps1')
$script:ShelterReleaseVersion = Read-ShelterVersion (Join-Path $PSScriptRoot '..\..\VERSION')
. (Join-Path $PSScriptRoot 'tools.ps1')
# END SHELTER SOURCE IMPORTS

function Read-ShelterOptions {
    param([string[]]$Arguments)
    $action = 'install'; $color = 'always'; $mode = 'lite'
    for ($i=0; $i -lt $Arguments.Count; $i++) {
        switch -CaseSensitive ($Arguments[$i]) {
            { $_ -in @('--help','-h') } { return @{ Action='help'; Color=$color } }
            { $_ -in @('--version','-V') } { return @{ Action='version'; Color=$color } }
            '--mode' {
                if ($i+1 -ge $Arguments.Count) { throw (Get-ShelterText value_required @('--mode')) }
                $mode = $Arguments[++$i]
            }
            '--color' {
                $color = 'always'
                if ($i+1 -lt $Arguments.Count -and -not $Arguments[$i+1].StartsWith('-')) { $color = $Arguments[++$i] }
                if ($color -cnotin @('always','auto','never')) { throw (Get-ShelterText invalid_color) }
                $script:ShelterColor = $color
            }
            { $_ -in @('--check','--dry-run') } {
                if ($action -ne 'install') { throw (Get-ShelterText conflicting_actions) }
                $action = $_.Substring(2)
            }
            default { throw (Get-ShelterText unknown_option @($Arguments[$i])) }
        }
    }
    if ($mode -eq 'full') { throw (Get-ShelterText full_unavailable) }
    if ($mode -ne 'lite') { throw (Get-ShelterText invalid_mode) }
    return @{ Action=$action; Color=$color }
}

function Write-ShelterPlan {
    param([object[]]$Probes)
    Write-ShelterSection before_installation
    Write-Host ('{0} {1}' -f [char]0xF03A,(Get-ShelterText table_header))
    for ($i=0; $i -lt $script:ShelterTools.Count; $i++) {
        $probe = $Probes[$i]
        $tone = switch ($probe.State) { ready {'success'} blocked {'error'} default {'warning'} }
        $dot = Get-ShelterColoredText $tone ([string][char]0x25CF)
        $status = Get-ShelterText ('status_' + $probe.State)
        if ($probe.Version) { $status += ' (' + $probe.Version + ')' }
        Write-Host ('{0}  {1,-18} | {2} | {3}' -f $dot,$script:ShelterToolNames[$script:ShelterTools[$i]],$status,(Get-ShelterText ('action_'+$probe.State)))
        if ($probe.Detail) { Write-ShelterMessage warning command_failed @($script:ShelterToolNames[$script:ShelterTools[$i]],$probe.Detail) }
    }
}

function Invoke-ShelterMain {
    param([string[]]$Arguments = @())
    $script:ShelterContext = @{ Log=''; Attempted=$false; Changed=$false }
    $script:ShelterColor = 'always'
    try { $options = Read-ShelterOptions $Arguments; $script:ShelterColor = $options.Color }
    catch { Write-ShelterMessage error detail @($_.Exception.Message); return 2 }
    if ($options.Action -eq 'help') { Write-Host (Get-ShelterText help); return 0 }
    if ($options.Action -eq 'version') { Write-Host (Get-ShelterText version @($script:ShelterReleaseVersion)); return 0 }
    Initialize-ShelterConsole
    try { $platform = Get-ShelterPlatform }
    catch { Write-ShelterMessage error command_failed @('Platform check',$_.Exception.Message); return 2 }

    try {
        if ($options.Action -ne 'check') { Write-ShelterLogo }
        if ($options.Action -eq 'install') {
            Initialize-ShelterLog
            Write-ShelterMessage note setup_starting
            # Preflight probes happen before any package/configuration changes.
        } else {
            $section = if ($options.Action -eq 'dry-run') { 'dry_run' } else { 'status_check' }
            Write-ShelterSection $section
            $intro = if ($options.Action -eq 'dry-run') { 'dry_run_intro' } else { 'check_intro' }
            Write-Host (Get-ShelterText $intro)
            Write-Host (Get-ShelterText platform_banner @($script:ShelterReleaseVersion,$platform))
        }
        $probes = @($script:ShelterTools | ForEach-Object { Get-ShelterToolProbe $_ })
        if ($options.Action -ne 'install') { Write-ShelterPlan $probes }
        $blocked = @($probes | Where-Object { $_.State -eq 'blocked' }).Count -gt 0
        $missing = @($probes | Where-Object { $_.State -ne 'ready' }).Count -gt 0
        if ($options.Action -eq 'check') {
            if ($missing) { Write-ShelterSection check_required warning; Write-Host (Get-ShelterText check_required_summary); return 1 }
            Write-ShelterSection check_complete success
            Write-Host (Get-ShelterText check_complete_summary)
            return 0
        }
        if ($blocked) { throw (Get-ShelterText blocked) }
        if ($options.Action -eq 'dry-run') {
            if ($probes[0].State -eq 'missing') { Write-ShelterMessage warning bootstrap_warning }
            if ($missing) { Write-ShelterMessage note agreements } else { Write-Host (Get-ShelterText nothing_to_install) }
            Write-ShelterSection planned_configuration
            Write-Host (Get-ShelterText configuration_plan)
            Write-ShelterSection dry_run_complete
            Write-Host (Get-ShelterText dry_run_summary)
            return 0
        }
        Write-ShelterMessage note agreements
        for ($i=0; $i -lt $script:ShelterTools.Count; $i++) {
            $tool = $script:ShelterTools[$i]
            # Recheck just before installation to avoid replacing newly detected tools.
            $probe = Get-ShelterToolProbe $tool
            Add-ShelterLog ($tool + ': ' + $probe.State + ' ' + $probe.Version + ' ' + $probe.Detail)
            if ($probe.State -eq 'blocked') { throw (Get-ShelterText blocked) }
            if ($probe.State -ne 'ready') {
                $script:ShelterContext.Attempted = $true
                Install-ShelterTool $tool $probe
                $probe = Get-ShelterToolProbe $tool
                if ($probe.State -ne 'ready') { throw (Get-ShelterText verification_failed @($script:ShelterToolNames[$tool])) }
            }
            $probes[$i] = $probe
        }
        Save-ShelterPaths $probes
        Write-ShelterSection installation_complete success
        Write-ShelterMessage success tools_ready
        if ($script:ShelterContext.Attempted -or $script:ShelterContext.Changed) { Write-ShelterMessage warning restart }
        Write-ShelterMessage note identity
        Write-ShelterMessage note log_path @($script:ShelterContext.Log)
        return 0
    } catch {
        Write-ShelterSection installation_failed error
        Write-ShelterMessage error command_failed @('Setup',$_.Exception.Message)
        if ($script:ShelterContext.Log) {
            try { Add-ShelterLog $_.Exception.ToString() } catch { }
            Write-ShelterMessage note log_path @($script:ShelterContext.Log)
        }
        if ($script:ShelterContext.Attempted -or $script:ShelterContext.Changed) { Write-ShelterMessage warning no_rollback }
        Write-ShelterMessage note retry
        return 1
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    $ErrorActionPreference = 'Stop'
    exit (Invoke-ShelterMain -Arguments @($args))
}
