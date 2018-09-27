#requires -Modules @{ ModuleName = 'BuildHelpers'; ModuleVersion = '2.0.0' }
#requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '4.4.0' }
#requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; ModuleVersion = '1.17.1' }

if(!$env:SCOOP_HOME) { $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop))) }
Invoke-Pester "$psscriptroot\..\"
