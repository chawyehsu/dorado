if (!$env:SCOOP_HOME) {
    $env:SCOOP_HOME = Resolve-Path (Split-Path (Split-Path (scoop which scoop)))
}
. "$env:SCOOP_HOME\test\Import-Bucket-Tests.ps1"
