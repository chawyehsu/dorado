#Requires -Version 5.1
Set-StrictMode -Version 3.0

# A temp fix for https://github.com/ScoopInstaller/Scoop/pull/5066#issuecomment-1372087032
function Invoke-ExternalCommand2 {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([Boolean])]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [Alias('Path')]
        [ValidateNotNullOrEmpty()]
        [String]
        $FilePath,
        [Parameter(Position = 1)]
        [Alias('Args')]
        [String[]]
        $ArgumentList,
        [Parameter(ParameterSetName = 'UseShellExecute')]
        [Switch]
        $RunAs,
        [Alias('Msg')]
        [String]
        $Activity,
        [Alias('cec')]
        [Hashtable]
        $ContinueExitCodes,
        [Parameter(ParameterSetName = 'Default')]
        [Alias('Log')]
        [String]
        $LogPath
    )
    if ($Activity) {
        Write-Host "$Activity " -NoNewline
    }
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo.FileName = $FilePath
    $Process.StartInfo.UseShellExecute = $false
    if ($LogPath) {
        if ($FilePath -match '^msiexec(.exe)?$') {
            $ArgumentList += "/lwe `"$LogPath`""
        } else {
            $Process.StartInfo.RedirectStandardOutput = $true
            $Process.StartInfo.RedirectStandardError = $true
        }
    }
    if ($RunAs) {
        $Process.StartInfo.UseShellExecute = $true
        $Process.StartInfo.Verb = 'RunAs'
    }
    if ($FilePath -match '^((cmd|cscript|wscript|msiexec)(\.exe)?|.*\.(bat|cmd|js|vbs|wsf))$') {
        $Process.StartInfo.Arguments = $ArgumentList -join ' '
    } elseif ($Process.StartInfo.ArgumentList.Add) {
        # ArgumentList is supported in PowerShell 6.1 and later (built on .NET Core 2.1+)
        # ref-1: https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.processstartinfo.argumentlist?view=net-6.0
        # ref-2: https://docs.microsoft.com/en-us/powershell/scripting/whats-new/differences-from-windows-powershell?view=powershell-7.2#net-framework-vs-net-core
        $ArgumentList | ForEach-Object { $Process.StartInfo.ArgumentList.Add($_) }
    } else {
        # escape arguments manually in lower versions, refer to https://docs.microsoft.com/en-us/previous-versions/17w5ykft(v=vs.85)
        $escapedArgs = $ArgumentList | ForEach-Object {
            # escape N consecutive backslash(es), which are followed by a double quote, to 2N consecutive ones
            $s = $_ -replace '(\\+)"', '$1$1"'
            # escape N consecutive backslash(es), which are at the end of the string, to 2N consecutive ones
            $s = $s -replace '(\\+)$', '$1$1'
            # escape double quotes
            $s = $s -replace '"', '\"'
            # quote the argument
            "`"$s`""
        }
        $Process.StartInfo.Arguments = $escapedArgs -join ' '
    }
    try {
        [void]$Process.Start()
    } catch {
        if ($Activity) {
            Write-Host 'error.' -ForegroundColor DarkRed
        }
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        return $false
    }
    $Process.WaitForExit()
    if ($Process.ExitCode -ne 0) {
        if ($ContinueExitCodes -and ($ContinueExitCodes.ContainsKey($Process.ExitCode))) {
            if ($Activity) {
                Write-Host 'done.' -ForegroundColor DarkYellow
            }
            Write-Host $ContinueExitCodes[$Process.ExitCode] -ForegroundColor DarkYellow
            return $true
        } else {
            if ($Activity) {
                Write-Host 'error.' -ForegroundColor DarkRed
            }
            Write-Host "Exit code was $($Process.ExitCode)!" -ForegroundColor DarkRed
            return $false
        }
    }
    if ($Activity) {
        Write-Host 'done.' -ForegroundColor Green
    }
    return $true
}

function Mount-ExternalRuntimeData {
    <#
    .SYNOPSIS
        Mount external runtime data

    .PARAMETER Source
        The source path, which is the persist_dir

    .PARAMETER Target
        The target path, which is the actual path app uses to access the runtime data
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Source,
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $Target
    )

    if (Test-Path $Source) {
        Remove-Item $Target -Force -Recurse -ErrorAction SilentlyContinue
    } else {
        New-Item -ItemType Directory $Source -Force | Out-Null
        if (Test-Path $Target) {
            Get-ChildItem $Target | Move-Item -Destination $Source -Force
            Remove-Item $Target
        }
    }

    New-Item -ItemType Junction -Path $Target -Target $Source -Force | Out-Null
}

function Dismount-ExternalRuntimeData {
    <#
    .SYNOPSIS
        Unmount external runtime data

    .PARAMETER Target
        The target path, which is the actual path app uses to access the runtime data
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Target
    )

    if (Test-Path $Target) {
        Remove-Item $Target -Force -Recurse
    }
}

Export-ModuleMember `
    -Function `
    Mount-ExternalRuntimeData, Dismount-ExternalRuntimeData, `
    Invoke-ExternalCommand2
