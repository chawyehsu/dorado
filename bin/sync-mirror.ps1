#Requires -Version 5
<#
.SYNOPSIS
    Sync repository to mirror git server.
.DESCRIPTION
    Push updates to mirror git server.
#>

$mirror = "git@git.dev.tencent.com:h404bi/dorado.git"
Invoke-Expression -command "git push $mirror"
