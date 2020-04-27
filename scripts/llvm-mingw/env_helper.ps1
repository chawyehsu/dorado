# An environment setup helper for llvm-mingw for PowerShell
# Created by Chawye Hsu (https://github.com/h404bi), licensed under the Unlicense.

# ensure the script file is in the right place.
if (!(Test-Path "$PSScriptRoot\bin\clang.exe")) {
    Write-Output "error: can't find clang executable."
    exit 1
}

$X_BIN = "$PSScriptRoot\bin"

function Set-Env {
    $env:Path = "$X_BIN;$env:Path"
}

function Remove-Env {
    $env:Path = $env:Path.Replace("$X_BIN;", "")
}

if ($args[0] -eq 'on') {
    if ($env:PATH -notlike "*$X_BIN*") {
        Set-Env
    } else {
        Write-Output "llvm-mingw has already turned on."
    }
} elseif ($args[0] -eq 'off') {
    if ($env:PATH -like "*$X_BIN*") {
        Remove-Env
    } else {
        Write-Output "llvm-mingw has already turned off."
    }
} else {
    Write-Output "Usage: llvm-mingw <on|off>"
    exit 1
}
