# Product metadata only. Keep the same SemVer contract as version.sh.
function Test-ShelterVersion {
    param([string]$Version)
    $number = '(0|[1-9][0-9]*)'
    $identifier = '(0|[1-9][0-9]*|[0-9]*[A-Za-z-][0-9A-Za-z-]*)'
    return $Version -cmatch "\A$number\.$number\.$number(?:-$identifier(?:\.$identifier)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?\z"
}

function Read-ShelterVersion {
    param([string]$Path)
    $value = [IO.File]::ReadAllText($Path).TrimEnd([char[]]"`r`n")
    if (-not (Test-ShelterVersion $value)) { throw "Invalid Semantic Version in: $Path" }
    return $value
}
