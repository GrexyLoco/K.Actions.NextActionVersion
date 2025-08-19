function Step-SemanticVersion {
    <#
    .SYNOPSIS
        Increments semantic version based on bump type
    
    .DESCRIPTION
        Takes a semantic version string and increments it based on the specified bump type:
        - major: X.Y.Z -> (X+1).0.0
        - minor: X.Y.Z -> X.(Y+1).0
        - patch: X.Y.Z -> X.Y.(Z+1)
    
    .PARAMETER Version
        Semantic version string (e.g., "1.2.3")
    
    .PARAMETER BumpType
        Type of version bump: "major", "minor", or "patch"
    
    .OUTPUTS
        String: New semantic version
    
    .EXAMPLE
        Step-SemanticVersion -Version "1.2.3" -BumpType "minor"
        # Returns "1.3.0"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("major", "minor", "patch")]
        [string]$BumpType
    )
    
    try {
        # Remove any 'v' prefix and pre-release suffixes
        $cleanVersion = $Version -replace '^v', '' -replace '-.*$', ''
        
        # Parse version components
        $versionParts = $cleanVersion -split '\.'
        if ($versionParts.Length -ne 3) {
            throw "Invalid semantic version format: $Version"
        }
        
        $major = [int]$versionParts[0]
        $minor = [int]$versionParts[1]
        $patch = [int]$versionParts[2]
        
        # Increment based on bump type
        switch ($BumpType) {
            "major" {
                $major++
                $minor = 0
                $patch = 0
            }
            "minor" {
                $minor++
                $patch = 0
            }
            "patch" {
                $patch++
            }
        }
        
        return "$major.$minor.$patch"
        
    } catch {
        Write-Warning "Error stepping version '$Version' with bump type '$BumpType': $($_.Exception.Message)"
        return $Version
    }
}