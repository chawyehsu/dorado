#Requires -Version 5.1
param(
    [String] $dir = "$PSScriptRoot\..\bucket",
    [Parameter(ValueFromRemainingArguments = $true)]
    [String[]] $remainArgs = @()
)

if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$checkver = "$env:SCOOP_HOME\bin\checkver.ps1"
$remainArgs = ($remainArgs | Select-Object -Unique) -join ' '

Invoke-Expression -Command "$checkver -dir $dir $remainArgs"
