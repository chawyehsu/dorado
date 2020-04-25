# An environment setup helper for nuwen-mingw for PowerShell
# Created by Chawye Hsu (https://github.com/h404bi), licensed under the Unlicense.

# ensure the script file is in the right place.
if (!(Test-Path "$PSScriptRoot\set_distro_paths.bat")) {
    exit 1
}

$X_BIN = "$PSScriptRoot\bin"
$X_MEOW = "$PSScriptRoot\include;$PSScriptRoot\include\freetype2"

function Set-NuwenMingwEnv {
    $env:Path = "$X_BIN;$env:Path"

    if ($env:C_INCLUDE_PATH) {
        $env:C_INCLUDE_PATH = "$X_MEOW;$env:C_INCLUDE_PATH"
    } else {
        $env:C_INCLUDE_PATH = $X_MEOW
    }

    if ($env:CPLUS_INCLUDE_PATH) {
        $env:CPLUS_INCLUDE_PATH = "$X_MEOW;$env:CPLUS_INCLUDE_PATH"
    } else {
        $env:CPLUS_INCLUDE_PATH = $X_MEOW
    }
}

function Remove-NuwenMingwEnv {
    $env:Path = $env:Path.Replace("$X_BIN;", "")

    if ($env:C_INCLUDE_PATH -eq "$X_MEOW") {
        $env:C_INCLUDE_PATH = ""
    } else {
        $env:C_INCLUDE_PATH = $env:C_INCLUDE_PATH.Replace("$X_MEOW;", "")
    }

    if ($env:CPLUS_INCLUDE_PATH -eq "$X_MEOW") {
        $env:CPLUS_INCLUDE_PATH = ""
    } else {
        $env:CPLUS_INCLUDE_PATH = $env:CPLUS_INCLUDE_PATH.Replace("$X_MEOW;", "")
    }
}

if ($args[0] -eq 'on') {
    if ($env:C_INCLUDE_PATH -notlike "*$X_MEOW*") {
        Set-NuwenMingwEnv
    } else {
        Write-Output "nuwen mingw has already turned on."
    }
} elseif ($args[0] -eq 'off') {
    if ($env:C_INCLUDE_PATH -like "*$X_MEOW*") {
        Remove-NuwenMingwEnv
    } else {
        Write-Output "nuwen mingw has already turned off."
    }
} else {
    Write-Output "Usage: mingw <on|off>"
    exit 1
}
