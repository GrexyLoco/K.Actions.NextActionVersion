function New-ActionVersionResult {
    <#
    .SYNOPSIS
        Creates standardized result object for NextActionVersion
    
    .DESCRIPTION
        Creates a consistent result object with all required properties
        for GitHub Actions integration
    
    .OUTPUTS
        PSCustomObject with standardized properties
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion,
        
        [Parameter(Mandatory = $true)]
        [string]$BumpType,
        
        [Parameter(Mandatory = $true)]
        [string]$NewVersion,
        
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$LastReleaseTag = "",
        
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,
        
        [Parameter(Mandatory = $false)]
        [string]$Suffix = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Warning = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$ActionRequired = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$ActionInstructions = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$IsFirstRelease = $false
    )
    
    return [PSCustomObject]@{
        CurrentVersion = $CurrentVersion
        BumpType = $BumpType
        NewVersion = $NewVersion
        LastReleaseTag = $LastReleaseTag
        TargetBranch = $TargetBranch
        Suffix = $Suffix
        Warning = $Warning
        ActionRequired = $ActionRequired
        ActionInstructions = $ActionInstructions
        IsFirstRelease = $IsFirstRelease
    }
}