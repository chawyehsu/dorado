#Requires -Version 5
# An environment setup helper for nuwen-mingw for PowerShell
# Created by Chawye Hsu (https://github.com/h404bi), licensed under the Unlicense.
# USE IT AT YOUR OWN RISK!

# ensure the script file is in the right place.
if (!(Test-Path "$PSScriptRoot\set_distro_paths.bat")) {
    Write-Output "can't find nuwen mingw binaries, abort."
    exit 1
}

$X_BIN = "$PSScriptRoot\bin"
$X_MEOW = "$PSScriptRoot\include;$PSScriptRoot\include\freetype2"

function Get-UserEnvironmentVariable([String]$key) {
    return [System.Environment]::GetEnvironmentVariable($key,`
        [System.EnvironmentVariableTarget]::User)
}

function Set-UserEnvironmentVariable([String]$key, [string]$value) {
    if ([String]::IsNullOrEmpty($value)) { $value = $null }
    [System.Environment]::SetEnvironmentVariable($key, $value,`
        [System.EnvironmentVariableTarget]::User)
}

function Set-NuwenMingwEnv {
    # PATH
    $userEnvPath = Get-UserEnvironmentVariable "PATH"
    # C_INCLUDE_PATH
    $userEnvCIncludePath = Get-UserEnvironmentVariable "C_INCLUDE_PATH"
    # CPLUS_INCLUDE_PATH
    $userEnvCplusIncludePath = Get-UserEnvironmentVariable "CPLUS_INCLUDE_PATH"

    # for future session
    Set-UserEnvironmentVariable "PATH" "$X_BIN;$userEnvPath"
    # for current session
    $env:Path = "$X_BIN;$env:Path"

    if ($userEnvCIncludePath) {
        # for future session
        Set-UserEnvironmentVariable "C_INCLUDE_PATH" "$X_MEOW;$userEnvCIncludePath"
        # for current session
        $env:C_INCLUDE_PATH = "$X_MEOW;$userEnvCIncludePath"
    } else {
        # for future session
        Set-UserEnvironmentVariable "C_INCLUDE_PATH" $X_MEOW
        # for current session
        $env:C_INCLUDE_PATH = $X_MEOW
    }

    if ($userEnvCplusIncludePath) {
        # for future session
        Set-UserEnvironmentVariable "CPLUS_INCLUDE_PATH" "$X_MEOW;$userEnvCplusIncludePath"
        # for current session
        $env:CPLUS_INCLUDE_PATH = "$X_MEOW;$env:CPLUS_INCLUDE_PATH"
    } else {
        # for future session
        Set-UserEnvironmentVariable "CPLUS_INCLUDE_PATH" $X_MEOW
        # for current session
        $env:CPLUS_INCLUDE_PATH = $X_MEOW
    }
}

function Remove-NuwenMingwEnv {
    # PATH
    $userEnvPath = Get-UserEnvironmentVariable "PATH"
    # C_INCLUDE_PATH
    $userEnvCIncludePath = Get-UserEnvironmentVariable "C_INCLUDE_PATH"
    # CPLUS_INCLUDE_PATH
    $userEnvCplusIncludePath = Get-UserEnvironmentVariable "CPLUS_INCLUDE_PATH"

    # for future session
    Set-UserEnvironmentVariable "PATH" $userEnvPath.Replace("$X_BIN;", "")
    # for current session
    $env:Path = $env:Path.Replace("$X_BIN;", "")

    # for future session
    Set-UserEnvironmentVariable "C_INCLUDE_PATH" $userEnvCIncludePath.Replace("$X_MEOW;", "").Replace("$X_MEOW", "")
    # for current session
    $env:C_INCLUDE_PATH = $env:C_INCLUDE_PATH.Replace("$X_MEOW;", "").Replace("$X_MEOW", "")

    # for future session
    Set-UserEnvironmentVariable "CPLUS_INCLUDE_PATH" $userEnvCplusIncludePath.Replace("$X_MEOW;", "").Replace("$X_MEOW", "")
    # for current session
    $env:CPLUS_INCLUDE_PATH = $env:CPLUS_INCLUDE_PATH.Replace("$X_MEOW;", "").Replace("$X_MEOW", "")
}

if ($args[0] -eq 'on') {
    if ($env:C_INCLUDE_PATH -notlike "*$X_MEOW*") {
        Set-NuwenMingwEnv
    }
    Write-Output "nuwen mingw has already turned on. Type 'gcc -v' for gcc info."
} elseif ($args[0] -eq 'off') {
    if ($env:C_INCLUDE_PATH -like "*$X_MEOW*") {
        Remove-NuwenMingwEnv
    }
    Write-Output "nuwen mingw has already turned off."
} elseif ($args[0] -eq 'status') {
    if ($env:C_INCLUDE_PATH -like "*$X_MEOW*") {
        Write-Output "nuwen mingw has already turned on. Environment variables:"
        Write-Output "C_INCLUDE_PATH: $env:C_INCLUDE_PATH"
        Write-Output "CPLUS_INCLUDE_PATH: $env:CPLUS_INCLUDE_PATH"
    } else {
        Write-Output "nuwen mingw has already turned off."
    }
} else {
    Write-Output "Usage: mingw <on|off|status>"
}
