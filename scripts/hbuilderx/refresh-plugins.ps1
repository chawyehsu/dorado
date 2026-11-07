#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $InstallDirectory,
    [Parameter(Mandatory = $true)]
    [string] $PersistDirectory
)

function Get-LiteralFilePath([string] $Path) {
    if ($PSVersionTable.PSEdition -eq 'Desktop' -and !$Path.StartsWith('\\?\')) {
        if ($Path.StartsWith('\\')) { return '\\?\UNC\' + $Path.Substring(2) }
        return '\\?\' + $Path
    }
    return $Path
}

function Remove-TransactionTree([string] $Path) {
    $literal = Get-LiteralFilePath $Path
    $item = Get-Item -LiteralPath $literal -Force -ErrorAction Stop
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw "Refusing to clean up reparse point '$Path'."
    }
    if ($item.PSIsContainer) {
        foreach ($child in Get-ChildItem -LiteralPath $literal -Force -ErrorAction Stop) {
            Remove-TransactionTree $child.FullName
        }
    }
    Remove-Item -LiteralPath $literal -Force -ErrorAction Stop
}

function Remove-Transaction([string] $Path) {
    # Keep the completion record until both payload directories are gone.
    foreach ($name in @('new', 'old')) {
        $payload = Join-Path $Path $name
        if (Test-Path -LiteralPath $payload -ErrorAction Stop) {
            Remove-TransactionTree $payload
        }
    }
    Remove-TransactionTree $Path
}

function Clear-CompletedTransactions([string] $PluginsDirectory) {
    $prefix = '.scoop-hbuilderx-'
    $completedTransactions = @()
    $protectedTransactions = @()
    $candidates = Get-ChildItem -LiteralPath $PluginsDirectory -Directory -Force -ErrorAction Stop |
        Where-Object { $_.Name -cmatch '^\.scoop-hbuilderx-[0-9a-f]{32}$' }
    foreach ($candidate in $candidates) {
        try {
            if ($candidate.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw 'The transaction directory is a reparse point.'
            }
            if (Test-Path -LiteralPath (Join-Path $candidate.FullName '.recovery-required') -ErrorAction Stop) {
                throw 'Recovery is required; inspect the retained backups manually.'
            }
            if (Test-Path -LiteralPath (Join-Path $candidate.FullName '.in-progress') -ErrorAction Stop) {
                throw 'The transaction is incomplete or was interrupted.'
            }
            $completed = Join-Path $candidate.FullName '.completed'
            if (!(Test-Path -LiteralPath $completed -PathType Leaf -ErrorAction Stop)) {
                throw 'There is no completion record; this may be a legacy transaction.'
            }
            $record = Get-Item -LiteralPath $completed -Force -ErrorAction Stop
            if ($record.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw 'The completion record is a reparse point.'
            }
            $expected = 'hbuilderx-plugin-refresh-v2:' + $candidate.Name.Substring($prefix.Length)
            if ([IO.File]::ReadAllText((Get-LiteralFilePath $completed)) -cne $expected) {
                throw 'The completion record is invalid.'
            }
            $entries = @(Get-ChildItem -LiteralPath $candidate.FullName -Force -ErrorAction Stop)
            if (@($entries | Where-Object { $_.Name -notin @('new', 'old', '.completed') }).Count) {
                throw 'The transaction contains unexpected entries.'
            }
            foreach ($name in @('new', 'old')) {
                $payload = Join-Path $candidate.FullName $name
                if (Test-Path -LiteralPath $payload -ErrorAction Stop) {
                    $item = Get-Item -LiteralPath $payload -Force -ErrorAction Stop
                    if (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                        throw "The '$name' payload is not a regular directory."
                    }
                    $children = @(Get-ChildItem -LiteralPath (Get-LiteralFilePath $payload) -Force -ErrorAction Stop)
                    if ($name -eq 'new' -and $children.Count) {
                        throw 'Staged plugins remain despite the completion record.'
                    }
                    if ($name -eq 'old') {
                        foreach ($child in $children) {
                            if (!(Test-Path -LiteralPath (Join-Path $PluginsDirectory $child.Name) -ErrorAction Stop)) {
                                throw "The backup of '$($child.Name)' has no current counterpart."
                            }
                        }
                    }
                }
            }
            $completedTransactions += $candidate.FullName
        } catch {
            $protectedTransactions += "'$($candidate.FullName)': $($_.Exception.Message)"
        }
    }
    if ($protectedTransactions.Count) {
        # Do not overwrite the current state or prune any backup while recovery is unresolved.
        throw "Cannot refresh HBuilderX until retained transactions are inspected. No plugin refresh or transaction cleanup was started. $($protectedTransactions -join '; ')"
    }
    foreach ($path in $completedTransactions) {
        try {
            Remove-Transaction $path
        } catch {
            Write-Warning "Preserving completed HBuilderX transaction '$path': $($_.Exception.Message)"
        }
    }
}

# This lock covers this refresh hook, not Scoop's later linking/persistence steps.
[IO.Directory]::CreateDirectory((Get-LiteralFilePath $PersistDirectory)) | Out-Null
$lockPath = Join-Path $PersistDirectory '.hbuilderx-plugin-refresh.lock'
try {
    $refreshLock = [IO.File]::Open((Get-LiteralFilePath $lockPath), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
} catch {
    throw "Cannot acquire the HBuilderX plugin refresh lock. Another refresh may be running or the lock is inaccessible. Run only one Scoop operation for HBuilderX at a time. $($_.Exception.Message)"
}

try {
    $pluginsDir = Join-Path $PersistDirectory 'plugins'
    if (!(Test-Path -LiteralPath $pluginsDir -PathType Container -ErrorAction Stop)) { return }
    Clear-CompletedTransactions $pluginsDir

    $transactionId = [guid]::NewGuid().ToString('N')
    $transaction = Join-Path $pluginsDir ('.scoop-hbuilderx-' + $transactionId)
    $staging = Join-Path $transaction 'new'
    $backup = Join-Path $transaction 'old'
    $active = Join-Path $transaction '.in-progress'
    $completed = Join-Path $transaction '.completed'
    $record = 'hbuilderx-plugin-refresh-v2:' + $transactionId
    $changes = @()
    $cleanupAllowed = $false
    try {
        [IO.Directory]::CreateDirectory((Get-LiteralFilePath $staging)) | Out-Null
        [IO.Directory]::CreateDirectory((Get-LiteralFilePath $backup)) | Out-Null
        [IO.File]::WriteAllText((Get-LiteralFilePath $active), $record)
        foreach ($plugin in Get-ChildItem -LiteralPath (Join-Path $InstallDirectory 'plugins') -Force -ErrorAction Stop) {
            $change = [pscustomobject]@{
                Target = Join-Path $pluginsDir $plugin.Name
                Staged = Join-Path $staging $plugin.Name
                Backup = Join-Path $backup $plugin.Name
                InstallStarted = $false
            }
            Copy-Item -LiteralPath (Get-LiteralFilePath $plugin.FullName) -Destination (Get-LiteralFilePath $change.Staged) -Recurse -Force -ErrorAction Stop
            $changes += $change
        }
        foreach ($change in $changes) {
            if (Test-Path -LiteralPath $change.Target -ErrorAction Stop) {
                Move-Item -LiteralPath $change.Target -Destination $change.Backup -ErrorAction Stop
            }
            $change.InstallStarted = $true
            Move-Item -LiteralPath $change.Staged -Destination $change.Target -ErrorAction Stop
        }
        # Atomic final step: only fully published refreshes are eligible for later cleanup.
        [IO.File]::Move((Get-LiteralFilePath $active), (Get-LiteralFilePath $completed))
        $cleanupAllowed = $true
    } catch {
        $failure = $_
        $rollbackErrors = @()
        for ($i = $changes.Count - 1; $i -ge 0; $i--) {
            $change = $changes[$i]
            try {
                if ($change.InstallStarted -and (Test-Path -LiteralPath $change.Target -ErrorAction Stop)) {
                    Remove-Item -LiteralPath $change.Target -Recurse -Force -ErrorAction Stop
                }
                if (Test-Path -LiteralPath $change.Backup -ErrorAction Stop) {
                    Move-Item -LiteralPath $change.Backup -Destination $change.Target -ErrorAction Stop
                }
            } catch {
                $rollbackErrors += $_.Exception.Message
            }
        }
        if ($rollbackErrors.Count) {
            try {
                [IO.File]::WriteAllText((Get-LiteralFilePath (Join-Path $transaction '.recovery-required')), $record)
            } catch {
                Write-Warning "Could not write the recovery record in '$transaction'; the incomplete transaction must be retained."
            }
            throw "HBuilderX plugin refresh failed: $($failure.Exception.Message). Rollback failed: $($rollbackErrors -join '; '). Backups retained in '$transaction'."
        }
        $cleanupAllowed = $true
        throw $failure
    } finally {
        # Pipeline cancellation can skip catch; never remove an uncommitted backup from finally.
        if ($cleanupAllowed -and (Test-Path -LiteralPath $transaction -ErrorAction Stop)) {
            try {
                Remove-Transaction $transaction
            } catch {
                Write-Warning "Could not clean up HBuilderX plugin staging directory '$transaction': $($_.Exception.Message)"
            }
        }
    }
} finally {
    # Keep the empty lock file: unlinking it could race with the next owner.
    $refreshLock.Dispose()
}
