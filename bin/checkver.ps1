param(
    [String] $dir = "$PSScriptRoot\..\bucket",
    [Parameter(ValueFromRemainingArguments = $true)]
    [String[]] $remainArgs = @()
)

if (!$env:SCOOP_HOME) {
    $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop)))
}

$checkver = "$env:SCOOP_HOME\bin\checkver.ps1"
$remainArgs = ($remainArgs | Select-Object -Unique) -join ' '

Invoke-Expression -command "$checkver -dir $dir $remainArgs"
