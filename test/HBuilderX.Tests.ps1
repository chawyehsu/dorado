#Requires -Version 5.1
param([string] $CrossVolumeInstallDir)

Describe 'HBuilderX bundled plugin refresh' {
    BeforeAll {
        $manifestPath = Join-Path (Split-Path $PSScriptRoot) 'bucket/hbuilderx.json'
        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $hook = [scriptblock]::Create($manifest.pre_install -join "`r`n")
        $moveItemCommand = Get-Command Move-Item -CommandType Cmdlet
        $copyItemCommand = Get-Command Copy-Item -CommandType Cmdlet
        $removeItemCommand = Get-Command Remove-Item -CommandType Cmdlet

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
            @(Get-ChildItem -LiteralPath (Join-Path $Fixture.Persist 'plugins') -Force |
                Where-Object { $_.Name.StartsWith('.scoop-hbuilderx-') })
        }
    }

    BeforeEach {
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
        Test-Path -LiteralPath $fixture.Persist | Should -BeFalse
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
