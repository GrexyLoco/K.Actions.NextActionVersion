#
# NextActionVersion.psm1
# 
# PowerShell module for GitHub Actions version management
# Uses Git tags as single source of truth for semantic versioning
#

# Import helper functions
. $PSScriptRoot\Functions\Private\Get-GitTags.ps1
. $PSScriptRoot\Functions\Private\Get-CommitsSinceTag.ps1
. $PSScriptRoot\Functions\Private\Step-SemanticVersion.ps1
. $PSScriptRoot\Functions\Private\New-ActionVersionResult.ps1
. $PSScriptRoot\Functions\Public\Get-NextActionVersion.ps1

# Export public functions
Export-ModuleMember -Function @(
    'Get-NextActionVersion'
)