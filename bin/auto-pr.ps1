#Requires -Version 5
param(
    # overwrite upstream param
    [String]$upstream = "chawyehsu/dorado:master"
)

if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$autopr = "$env:SCOOP_HOME/bin/auto-pr.ps1"
$dir = "$psscriptroot/../bucket" # checks the parent dir
Invoke-Expression -command "$autopr -dir $dir -upstream $upstream $($args | ForEach-Object { "$_ " })"
