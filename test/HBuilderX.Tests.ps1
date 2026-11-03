#Requires -Version 5.1
param([string] $CrossVolumeInstallDir)

Describe 'HBuilderX bundled plugin refresh' {
    BeforeAll {
        $bucketRoot = Split-Path $PSScriptRoot
        $refreshScript = Join-Path $bucketRoot 'scripts/hbuilderx/refresh-plugins.ps1'
        $manifestPath = Join-Path $bucketRoot 'bucket/hbuilderx.json'
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $hook = [scriptblock]::Create($manifest.pre_install -join "`r`n")
        $moveItemCommand = Get-Command Move-Item -CommandType Cmdlet
        $copyItemCommand = Get-Command Copy-Item -CommandType Cmdlet
        $removeItemCommand = Get-Command Remove-Item -CommandType Cmdlet
        $faults = [pscustomobject]@{
            BlockOldCleanup = $false
            InjectRefreshFailure = $false
            InjectCopyFailure = $false
            BlockStagedCleanup = $false
        }

        function Find-BucketDirectory([switch] $Root, [string] $Name) {
            if (!$Root -or $Name -ne 'dorado') { throw 'Unexpected bucket lookup' }
            return $bucketRoot
        }

        function New-PluginFixture([string] $Root) {
            $install = Join-Path $Root 'install'
            $persist = Join-Path $Root 'persist'
            [IO.Directory]::CreateDirectory((Join-Path $install 'plugins')) | Out-Null
            [IO.Directory]::CreateDirectory((Join-Path $persist 'plugins')) | Out-Null
            [pscustomobject]@{ Install = $install; Persist = $persist }
        }

        function Set-PluginState([string] $Root, [string] $Name, [string] $Value) {
            $path = Join-Path (Join-Path $Root 'plugins') $Name
            [IO.Directory]::CreateDirectory($path) | Out-Null
            [IO.File]::WriteAllText((Join-Path $path 'state.txt'), $Value)
        }

        function Get-PluginState([string] $Root, [string] $Name) {
            [IO.File]::ReadAllText((Join-Path (Join-Path (Join-Path $Root 'plugins') $Name) 'state.txt'))
        }

        function Invoke-PluginRefresh($Fixture) {
            $dir = $Fixture.Install
            $persist_dir = $Fixture.Persist
            Invoke-Command -ScriptBlock $hook
        }

        function Get-Transactions($Fixture) {
            @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Persist 'plugins') -Directory -Force |
                Where-Object { $_.Name -cmatch '^\.scoop-hbuilderx-[0-9a-f]{32}$' })
        }

        function New-RetainedTransaction($Fixture, [string] $State, [string] $BackupName = 'a-bundled') {
            $id = [guid]::NewGuid().ToString('N')
            $path = Join-Path (Join-Path $Fixture.Persist 'plugins') ('.scoop-hbuilderx-' + $id)
            [IO.Directory]::CreateDirectory((Join-Path $path 'new')) | Out-Null
            $oldPlugin = Join-Path (Join-Path $path 'old') $BackupName
            [IO.Directory]::CreateDirectory($oldPlugin) | Out-Null
            [IO.File]::WriteAllText((Join-Path $oldPlugin 'state.txt'), 'retained backup')
            $record = 'hbuilderx-plugin-refresh-v2:' + $id
            if ($State -in @('completed', 'ambiguous', 'invalid')) {
                $content = if ($State -eq 'invalid') { 'incomplete record' } else { $record }
                [IO.File]::WriteAllText((Join-Path $path '.completed'), $content)
            }
            if ($State -in @('active', 'ambiguous', 'recovery')) {
                [IO.File]::WriteAllText((Join-Path $path '.in-progress'), $record)
            }
            if ($State -eq 'recovery') {
                [IO.File]::WriteAllText((Join-Path $path '.recovery-required'), $record)
            }
            return $path
        }
    }

    BeforeEach {
        $faults.BlockOldCleanup = $false
        $faults.InjectRefreshFailure = $false
        $faults.InjectCopyFailure = $false
        $faults.BlockStagedCleanup = $false
        $fixture = New-PluginFixture (Join-Path $TestDrive ([guid]::NewGuid().ToString('N')))
        Set-PluginState $fixture.Install 'a-bundled' 'new-a'
        Set-PluginState $fixture.Install 'b-bundled' 'new-b'
        Set-PluginState $fixture.Persist 'a-bundled' 'old-a'
        Set-PluginState $fixture.Persist 'b-bundled' 'old-b'
        Set-PluginState $fixture.Persist 'user-plugin' 'user-state'
    }

    It 'leaves a fresh installation for Scoop to persist' {
        $fixture.Persist = Join-Path $TestDrive 'fresh-persist'
        Invoke-PluginRefresh $fixture
        Test-Path -LiteralPath (Join-Path $fixture.Persist 'plugins') | Should -BeFalse
        Get-PluginState $fixture.Install 'a-bundled' | Should -Be 'new-a'
    }

    It 'refreshes bundled plugins, preserves unrelated plugins and leaves the source intact' {
        $stale = Join-Path $fixture.Persist 'plugins/a-bundled/stale.txt'
        [IO.File]::WriteAllText($stale, 'obsolete')
        Set-PluginState $fixture.Install 'new-plugin' 'new-plugin-state'
        Invoke-PluginRefresh $fixture
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'new-a'
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'new-b'
        Get-PluginState $fixture.Persist 'new-plugin' | Should -Be 'new-plugin-state'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        Get-PluginState $fixture.Install 'a-bundled' | Should -Be 'new-a'
        Test-Path -LiteralPath $stale | Should -BeFalse
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'treats bracketed installation, persistence and plugin names literally' {
        $fixture = New-PluginFixture (Join-Path $TestDrive 'root [work]')
        Set-PluginState $fixture.Install 'bundled[core]' 'new'
        Set-PluginState $fixture.Persist 'bundled[core]' 'old'
        Set-PluginState $fixture.Persist 'bundledc' 'unrelated'
        Invoke-PluginRefresh $fixture
        Get-PluginState $fixture.Persist 'bundled[core]' | Should -Be 'new'
        Get-PluginState $fixture.Persist 'bundledc' | Should -Be 'unrelated'
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'copies plugin files whose temporary staging path exceeds the legacy Windows limit' {
        $sourcePlugin = Join-Path $fixture.Install 'plugins/a-bundled'
        $deepDirectory = Join-Path $sourcePlugin ('x' * [Math]::Max(1, 230 - $sourcePlugin.Length))
        [IO.Directory]::CreateDirectory($deepDirectory) | Out-Null
        [IO.File]::WriteAllText((Join-Path $deepDirectory 'deep.txt'), 'deep plugin data')
        Invoke-PluginRefresh $fixture
        # A second refresh must also clean up the now-deep old-plugin backup.
        Invoke-PluginRefresh $fixture
        $copied = Join-Path (Join-Path $fixture.Persist 'plugins/a-bundled') (Split-Path $deepDirectory -Leaf)
        [IO.File]::ReadAllText((Join-Path $copied 'deep.txt')) | Should -Be 'deep plugin data'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'does not touch old plugins when staging a copy fails' {
        Mock Move-Item { throw 'No moves should occur during staging' }
        Mock Copy-Item {
            param($LiteralPath, $Destination)
            if ([IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') { throw 'Injected copy failure' }
            & $copyItemCommand -LiteralPath $LiteralPath -Destination $Destination -Recurse -Force -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Injected copy failure*'
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        Should -Invoke Move-Item -Times 0 -Exactly
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'restores every replaced plugin when publishing a later plugin fails' {
        Mock Move-Item {
            param($LiteralPath, $Destination)
            if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath)) -eq 'new' -and
                [IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') { throw 'Injected move failure' }
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Injected move failure*'
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        Get-PluginState $fixture.Install 'b-bundled' | Should -Be 'new-b'
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter {
            [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath)) -eq 'old' -and
            [IO.Path]::GetFileName($LiteralPath) -eq 'a-bundled'
        }
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'removes a partially published replacement before restoring the old plugin' {
        Mock Move-Item {
            param($LiteralPath, $Destination)
            if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath)) -eq 'new' -and
                [IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') {
                [IO.Directory]::CreateDirectory($Destination) | Out-Null
                [IO.File]::WriteAllText((Join-Path $Destination 'partial.txt'), 'partial')
                throw 'Injected partial move failure'
            }
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Injected partial move failure*'
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
        Test-Path -LiteralPath (Join-Path $fixture.Persist 'plugins/b-bundled/partial.txt') | Should -BeFalse
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'removes newly added plugins when a later replacement fails' {
        $fixture = New-PluginFixture (Join-Path $TestDrive 'new-plugin-rollback')
        Set-PluginState $fixture.Install 'a-new' 'new'
        Set-PluginState $fixture.Install 'b-bundled' 'new-b'
        Set-PluginState $fixture.Persist 'b-bundled' 'old-b'
        Mock Move-Item {
            param($LiteralPath, $Destination)
            if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath)) -eq 'new' -and
                [IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') { throw 'Injected move failure' }
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Injected move failure*'
        Test-Path -LiteralPath (Join-Path $fixture.Persist 'plugins/a-new') | Should -BeFalse
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'retains backups and reports both errors when rollback itself is blocked' {
        Mock Move-Item {
            param($LiteralPath, $Destination)
            $parent = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath))
            $name = [IO.Path]::GetFileName($LiteralPath)
            if ($parent -eq 'new' -and $name -eq 'b-bundled') { throw 'Injected publish failure' }
            if ($parent -eq 'old' -and $name -eq 'a-bundled') { throw 'Injected restore failure' }
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Injected publish failure*Injected restore failure*Backups retained*'
        $transactions = @(Get-Transactions $fixture)
        $transactions.Count | Should -Be 1
        [IO.File]::ReadAllText((Join-Path $transactions[0].FullName 'old/a-bundled/state.txt')) | Should -Be 'old-a'
        Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
    }

    It 'keeps the successful update and warns when backup cleanup is blocked' {
        Mock Remove-Item {
            param($LiteralPath)
            if ([IO.Path]::GetFileName($LiteralPath).StartsWith('.scoop-hbuilderx-')) { throw 'Injected cleanup failure' }
            & $removeItemCommand -LiteralPath $LiteralPath -Recurse -Force -ErrorAction Stop
        }
        $warnings = @(Invoke-PluginRefresh $fixture 3>&1)
        $warnings.Count | Should -Be 1
        $warnings[0].ToString() | Should -BeLike '*Injected cleanup failure*'
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'new-a'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        @(Get-Transactions $fixture).Count | Should -Be 1
    }

    It 'prunes a completed transaction and preserves unrelated user plugins' {
        $retained = New-RetainedTransaction $fixture 'completed'
        Invoke-PluginRefresh $fixture
        Test-Path -LiteralPath $retained | Should -BeFalse
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'preserves <State> transactions rather than guessing that their backups are disposable' -ForEach @(
        @{ State = 'legacy' },
        @{ State = 'active' },
        @{ State = 'recovery' },
        @{ State = 'ambiguous' },
        @{ State = 'invalid' }
    ) {
        $retained = New-RetainedTransaction $fixture $State
        { Invoke-PluginRefresh $fixture } | Should -Throw '*retained transactions are inspected*'
        [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'retained backup'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
    }

    It 'preserves a completed backup when its current plugin counterpart is missing' {
        $retained = New-RetainedTransaction $fixture 'completed' 'missing-plugin'
        { Invoke-PluginRefresh $fixture } | Should -Throw '*no current counterpart*'
        [IO.File]::ReadAllText((Join-Path $retained 'old/missing-plugin/state.txt')) | Should -Be 'retained backup'
    }

    It 'does not prune other backups or change plugins when any transaction needs inspection' {
        $completed = New-RetainedTransaction $fixture 'completed'
        $incomplete = New-RetainedTransaction $fixture 'active'
        Mock Copy-Item { throw 'No copying is safe before retained transactions are inspected' }
        Mock Move-Item { throw 'No swapping is safe before retained transactions are inspected' }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*No plugin refresh or transaction cleanup was started*'
        Test-Path -LiteralPath (Join-Path $completed 'old/a-bundled/state.txt') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $incomplete 'old/a-bundled/state.txt') | Should -BeTrue
        Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
        Should -Invoke Copy-Item -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
    }

    It 'preserves completed directories containing unexpected or still-staged data' -ForEach @(
        @{ Extra = 'recovery-notes.txt' },
        @{ Extra = 'new/unpublished.txt' }
    ) {
        $retained = New-RetainedTransaction $fixture 'completed'
        [IO.File]::WriteAllText((Join-Path $retained $Extra), 'preserve this data')
        { Invoke-PluginRefresh $fixture } | Should -Throw '*retained transactions are inspected*'
        [IO.File]::ReadAllText((Join-Path $retained $Extra)) | Should -Be 'preserve this data'
    }

    It 'keeps the completion record if payload cleanup fails and retries on the next refresh' {
        $faults.BlockOldCleanup = $true
        Mock Remove-Item {
            param($LiteralPath)
            if ($faults.BlockOldCleanup -and $LiteralPath.EndsWith('\old\a-bundled\state.txt')) {
                throw 'Injected payload cleanup failure'
            }
            & $removeItemCommand -LiteralPath $LiteralPath -Force -ErrorAction Stop
        }
        $warnings = @(Invoke-PluginRefresh $fixture 3>&1)
        $warnings[0].ToString() | Should -BeLike '*Injected payload cleanup failure*'
        $retained = @(Get-Transactions $fixture)[0].FullName
        Test-Path -LiteralPath (Join-Path $retained '.completed') | Should -BeTrue
        [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'old-a'
        $faults.BlockOldCleanup = $false
        Invoke-PluginRefresh $fixture
        Test-Path -LiteralPath $retained | Should -BeFalse
        @(Get-Transactions $fixture).Count | Should -Be 0
    }

    It 'protects recovery backups on subsequent refreshes after a failed rollback' {
        $faults.InjectRefreshFailure = $true
        Mock Move-Item {
            param($LiteralPath, $Destination)
            $parent = [IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath))
            $name = [IO.Path]::GetFileName($LiteralPath)
            if ($faults.InjectRefreshFailure -and $parent -eq 'new' -and $name -eq 'b-bundled') { throw 'Publish failure' }
            if ($faults.InjectRefreshFailure -and $parent -eq 'old' -and $name -eq 'a-bundled') { throw 'Restore failure' }
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Backups retained*'
        $retained = @(Get-Transactions $fixture)[0].FullName
        Test-Path -LiteralPath (Join-Path $retained '.recovery-required') | Should -BeTrue
        $faults.InjectRefreshFailure = $false
        { Invoke-PluginRefresh $fixture } | Should -Throw '*Recovery is required*'
        [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'old-a'
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
    }

    It 'retains an incomplete transaction if cleanup also fails after a copy error' {
        $faults.InjectCopyFailure = $true
        $faults.BlockStagedCleanup = $true
        Mock Copy-Item {
            param($LiteralPath, $Destination)
            if ($faults.InjectCopyFailure -and [IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') { throw 'Copy failure' }
            & $copyItemCommand -LiteralPath $LiteralPath -Destination $Destination -Recurse -Force -ErrorAction Stop
        }
        Mock Remove-Item {
            param($LiteralPath)
            if ($faults.BlockStagedCleanup -and $LiteralPath.EndsWith('\new\a-bundled\state.txt')) { throw 'Cleanup failure' }
            & $removeItemCommand -LiteralPath $LiteralPath -Force -ErrorAction Stop
        }
        { Invoke-PluginRefresh $fixture 3>$null } | Should -Throw '*Copy failure*'
        $retained = @(Get-Transactions $fixture)[0].FullName
        Test-Path -LiteralPath (Join-Path $retained '.in-progress') | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $retained '.completed') | Should -BeFalse
        $faults.InjectCopyFailure = $false
        $faults.BlockStagedCleanup = $false
        { Invoke-PluginRefresh $fixture } | Should -Throw '*incomplete or was interrupted*'
        Test-Path -LiteralPath (Join-Path $retained 'new/a-bundled/state.txt') | Should -BeTrue
    }

    It 'rejects an overlapping process before it can interfere with rollback or cleanup' {
        $ready = Join-Path $TestDrive 'refresh-ready'
        $release = Join-Path $TestDrive 'refresh-release'
        $job = Start-Job -ArgumentList $refreshScript, $fixture.Install, $fixture.Persist, $ready, $release -ScriptBlock {
            param($ScriptPath, $InstallPath, $PersistPath, $ReadyPath, $ReleasePath)
            $copyCommand = Get-Command Copy-Item -CommandType Cmdlet
            $moveCommand = Get-Command Move-Item -CommandType Cmdlet
            function Copy-Item {
                [CmdletBinding()]
                param($LiteralPath, $Destination, [switch] $Recurse, [switch] $Force)
                [IO.File]::WriteAllText($ReadyPath, 'locked')
                $timeout = [Diagnostics.Stopwatch]::StartNew()
                while (!(Test-Path -LiteralPath $ReleasePath)) {
                    if ($timeout.Elapsed.TotalSeconds -gt 10) { throw 'Concurrent test release timed out' }
                    Start-Sleep -Milliseconds 50
                }
                & $copyCommand -LiteralPath $LiteralPath -Destination $Destination -Recurse -Force -ErrorAction Stop
            }
            function Move-Item {
                [CmdletBinding()]
                param($LiteralPath, $Destination)
                if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($LiteralPath)) -eq 'new' -and
                    [IO.Path]::GetFileName($LiteralPath) -eq 'b-bundled') { throw 'Concurrent owner publish failure' }
                & $moveCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
            }
            try { & $ScriptPath -InstallDirectory $InstallPath -PersistDirectory $PersistPath -ErrorAction Stop }
            catch { $_.Exception.Message }
        }
        try {
            $timeout = [Diagnostics.Stopwatch]::StartNew()
            while (!(Test-Path -LiteralPath $ready)) {
                if ($timeout.Elapsed.TotalSeconds -gt 10) { throw 'Concurrent test owner did not acquire the lock' }
                Start-Sleep -Milliseconds 50
            }
            Mock Copy-Item { throw 'The overlapping refresh must not start copying' }
            { Invoke-PluginRefresh $fixture } | Should -Throw '*Cannot acquire the HBuilderX plugin refresh lock*'
            Should -Invoke Copy-Item -Times 0 -Exactly
            [IO.File]::WriteAllText($release, 'continue')
            $job | Wait-Job -Timeout 10 | Out-Null
            $job.State | Should -Be 'Completed'
            @($job | Receive-Job) -join '' | Should -BeLike '*Concurrent owner publish failure*'
            Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
            Get-PluginState $fixture.Persist 'b-bundled' | Should -Be 'old-b'
            Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
            @(Get-Transactions $fixture).Count | Should -Be 0
        } finally {
            [IO.File]::WriteAllText($release, 'continue')
            if ($job.State -eq 'Running') { $job | Stop-Job }
            $job | Remove-Job -Force
        }
        $lockPath = Join-Path $fixture.Persist '.hbuilderx-plugin-refresh.lock'
        $handle = [IO.File]::Open($lockPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $handle.Dispose()
    }

    It 'does not prune even a completed directory while another owner holds the refresh lock' {
        $retained = New-RetainedTransaction $fixture 'completed'
        $lockPath = Join-Path $fixture.Persist '.hbuilderx-plugin-refresh.lock'
        $owner = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try {
            { Invoke-PluginRefresh $fixture } | Should -Throw '*Cannot acquire the HBuilderX plugin refresh lock*'
            [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'retained backup'
            Get-PluginState $fixture.Persist 'a-bundled' | Should -Be 'old-a'
        } finally {
            $owner.Dispose()
        }
        Invoke-PluginRefresh $fixture
        Test-Path -LiteralPath $retained | Should -BeFalse
    }

    It 'keeps the only old copy when its owner is forcibly stopped after backing up a plugin' {
        $ready = Join-Path $TestDrive 'interrupted-refresh-ready'
        $job = Start-Job -ArgumentList $refreshScript, $fixture.Install, $fixture.Persist, $ready -ScriptBlock {
            param($ScriptPath, $InstallPath, $PersistPath, $ReadyPath)
            $moveCommand = Get-Command Move-Item -CommandType Cmdlet
            function Move-Item {
                [CmdletBinding()]
                param($LiteralPath, $Destination)
                & $moveCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
                if ([IO.Path]::GetFileName([IO.Path]::GetDirectoryName($Destination)) -eq 'old' -and
                    [IO.Path]::GetFileName($Destination) -eq 'a-bundled') {
                    [IO.File]::WriteAllText($ReadyPath, 'backed up')
                    $timeout = [Diagnostics.Stopwatch]::StartNew()
                    while ($timeout.Elapsed.TotalSeconds -lt 10) { Start-Sleep -Milliseconds 50 }
                    throw 'The interruption test did not stop its owner'
                }
            }
            & $ScriptPath -InstallDirectory $InstallPath -PersistDirectory $PersistPath -ErrorAction Stop
        }
        try {
            $timeout = [Diagnostics.Stopwatch]::StartNew()
            while (!(Test-Path -LiteralPath $ready)) {
                if ($timeout.Elapsed.TotalSeconds -gt 10) { throw 'Interrupted owner did not reach its backup step' }
                Start-Sleep -Milliseconds 50
            }
            $job | Stop-Job
            $job.State | Should -Be 'Stopped'
            $retained = @(Get-Transactions $fixture)[0].FullName
            Test-Path -LiteralPath (Join-Path $retained '.in-progress') | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $retained '.completed') | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $fixture.Persist 'plugins/a-bundled') | Should -BeFalse
            [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'old-a'
            { Invoke-PluginRefresh $fixture } | Should -Throw '*incomplete or was interrupted*'
            [IO.File]::ReadAllText((Join-Path $retained 'old/a-bundled/state.txt')) | Should -Be 'old-a'
        } finally {
            if ($job.State -eq 'Running') { $job | Stop-Job }
            $job | Remove-Job -Force
        }
    }

    It 'stages across volumes and only moves files within the persist volume' -Skip:(!$CrossVolumeInstallDir) {
        [IO.Path]::GetPathRoot($CrossVolumeInstallDir) | Should -Not -Be ([IO.Path]::GetPathRoot($fixture.Persist))
        $fixture.Install = $CrossVolumeInstallDir
        $sourcePlugins = Join-Path $fixture.Install 'plugins'
        $sourceFiles = @(Get-ChildItem -LiteralPath $sourcePlugins -File -Recurse | Select-Object -First 5)
        $sourceFiles.Count | Should -BeGreaterThan 0
        $hashes = @($sourceFiles | ForEach-Object { (Get-FileHash -LiteralPath $_.FullName).Hash })
        Mock Move-Item {
            param($LiteralPath, $Destination)
            [IO.Path]::GetPathRoot($LiteralPath) | Should -Be ([IO.Path]::GetPathRoot($Destination))
            & $moveItemCommand -LiteralPath $LiteralPath -Destination $Destination -ErrorAction Stop
        }
        Invoke-PluginRefresh $fixture
        foreach ($plugin in Get-ChildItem -LiteralPath $sourcePlugins -Force) {
            Test-Path -LiteralPath (Join-Path (Join-Path $fixture.Persist 'plugins') $plugin.Name) | Should -BeTrue
        }
        for ($i = 0; $i -lt $sourceFiles.Count; $i++) {
            (Get-FileHash -LiteralPath $sourceFiles[$i].FullName).Hash | Should -Be $hashes[$i]
        }
        Get-PluginState $fixture.Persist 'user-plugin' | Should -Be 'user-state'
        @(Get-Transactions $fixture).Count | Should -Be 0
    }
}
