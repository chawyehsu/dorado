Remove-NetFirewallRule -Description "Work with Clash for Windows v* installed by scoop/dorado." -ErrorAction SilentlyContinue
'TCP', 'UDP' | ForEach-Object {
    New-NetFirewallRule `
        -DisplayName "Clash for Windows" `
        -Profile "Private, Public" `
        -Description "Work with Clash for Windows v$version installed by scoop/dorado." `
        -Direction Inbound `
        -Protocol $_ `
        -Action Allow `
        -Program "$CFWPath" `
        -EdgeTraversalPolicy DeferToUser `
        | Out-Null
    New-NetFirewallRule `
        -DisplayName "Clash Core" `
        -Profile "Private, Public" `
        -Description "Work with Clash for Windows v$version installed by scoop/dorado." `
        -Direction Inbound `
        -Protocol $_ `
        -Action Allow `
        -Program "$CorePath" `
        | Out-Null
}
