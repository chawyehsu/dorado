#Requires -Version 5
if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$formatjson = "$env:SCOOP_HOME\bin\formatjson.ps1"
$dir = "$psscriptroot\..\bucket" # checks the parent dir
Invoke-Expression -command "$formatjson -dir $dir $($args | ForEach-Object { "$_ " })"
