#Requires -Version 5.1
if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$checkhashes = "$env:SCOOP_HOME\bin\checkhashes.ps1"
$dir = "$psscriptroot\..\bucket" # checks the parent dir
Invoke-Expression -Command "$checkhashes -dir $dir $($args | ForEach-Object { "$_ " })"
