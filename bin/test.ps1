#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '4.4.0' }

if (!$env:SCOOP_HOME) { $env:SCOOP_HOME = Resolve-Path (scoop prefix scoop) }
$result = Invoke-Pester "$PSScriptRoot\..\test" -PassThru
exit $result.FailedCount
