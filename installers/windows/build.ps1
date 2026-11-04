param([string]$OutputDirectory = (Join-Path $PSScriptRoot '..\..\dist'))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'messages.ps1')
. (Join-Path $PSScriptRoot '..\..\scripts\version.ps1')
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$version = Read-ShelterVersion (Join-Path $root 'VERSION')
$output = [IO.Path]::GetFullPath($OutputDirectory)
[void][IO.Directory]::CreateDirectory($output)
$stage = Join-Path $output ('.shelter-build-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($stage)
try {
    $license = ([IO.File]::ReadAllLines((Join-Path $root 'LICENSE')) | ForEach-Object { '# ' + $_ }) -join "`n"
    $content = "# Shelter Lite standalone installer - generated; do not edit.`n# Source: https://github.com/4BFC/shelter`n$license`n"
    $content += '$script:ShelterReleaseVersion = ''' + $version + "'`n"
    foreach ($source in @('messages.ps1','..\..\scripts\version.ps1','tools.ps1')) {
        $content += [IO.File]::ReadAllText((Join-Path $PSScriptRoot $source)) + "`n"
    }
    $entry = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'install.ps1'))
    $pattern = '(?ms)^# BEGIN SHELTER SOURCE IMPORTS\r?\n.*?^# END SHELTER SOURCE IMPORTS\r?\n'
    if ([regex]::Matches($entry,$pattern).Count -ne 1 -or
        [regex]::Matches($entry,'(?m)^# BEGIN SHELTER SOURCE IMPORTS\r?$').Count -ne 1 -or
        [regex]::Matches($entry,'(?m)^# END SHELTER SOURCE IMPORTS\r?$').Count -ne 1) { throw 'Source import markers are invalid.' }
    $content += [regex]::Replace($entry,$pattern,'')
    $utf8 = New-Object Text.UTF8Encoding($true)
    $scriptPath = Join-Path $stage 'shelter-lite-windows.ps1'
    [IO.File]::WriteAllText($scriptPath,$content.Replace("`r`n","`n"),$utf8)
    $tokens=$null; $errors=$null
    [void][Management.Automation.Language.Parser]::ParseFile($scriptPath,[ref]$tokens,[ref]$errors)
    if ($errors.Count -gt 0) { throw ($errors | Out-String) }
    [IO.File]::WriteAllText((Join-Path $stage 'Shelter Lite.cmd'),([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'launch.cmd')) -replace '\r?\n',"`r`n"),[Text.Encoding]::ASCII)
    [IO.File]::WriteAllText((Join-Path $stage 'VERSION'),$version+"`n",(New-Object Text.UTF8Encoding($false)))
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archivePath = Join-Path $stage 'shelter-lite-windows.zip'
    $archive = [IO.Compression.ZipFile]::Open($archivePath,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($name in @('shelter-lite-windows.ps1','Shelter Lite.cmd','VERSION')) {
            $entry = $archive.CreateEntry($name,[IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [DateTimeOffset]::new(1980,1,1,0,0,0,[TimeSpan]::Zero)
            $stream = $entry.Open()
            try { $bytes=[IO.File]::ReadAllBytes((Join-Path $stage $name)); $stream.Write($bytes,0,$bytes.Length) }
            finally { $stream.Dispose() }
        }
    } finally { $archive.Dispose() }
    foreach ($name in @('shelter-lite-windows.ps1','shelter-lite-windows.zip')) {
        $hash = (Get-FileHash -LiteralPath (Join-Path $stage $name) -Algorithm SHA256).Hash.ToLowerInvariant()
        [IO.File]::WriteAllText((Join-Path $stage ($name+'.sha256')),$hash+'  '+$name+"`n",[Text.Encoding]::ASCII)
    }
    $names = @('shelter-lite-windows.ps1','shelter-lite-windows.ps1.sha256','shelter-lite-windows.zip','shelter-lite-windows.zip.sha256','VERSION')
    foreach ($name in $names) {
        if (Test-Path -LiteralPath (Join-Path $output $name) -PathType Container) { throw "Output is a directory: $name" }
    }
    foreach ($name in $names) {
        Move-Item -LiteralPath (Join-Path $stage $name) -Destination (Join-Path $output $name) -Force
        Write-Host (Get-ShelterText build_complete @((Join-Path $output $name)))
    }
} finally { Remove-Item -LiteralPath $stage -Recurse -Force }
