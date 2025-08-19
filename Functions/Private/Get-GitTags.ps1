function Get-GitTags {
    <#
    .SYNOPSIS
        Gets sorted list of semantic version tags from Git repository
    
    .DESCRIPTION
        Retrieves all Git tags that match semantic versioning pattern (v1.0.0, 1.0.0)
        and sorts them in descending order (newest first)
    
    .OUTPUTS
        Array of tag names sorted by semantic version (newest first)
    #>
    
    try {
        # Get all tags from Git
        $allTags = git tag -l 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $allTags) {
            return @()
        }
        
        # Filter for semantic version tags and sort
        $semverPattern = '^v?\d+\.\d+\.\d+.*$'
        $semverTags = $allTags | Where-Object { $_ -match $semverPattern }
        
        if (-not $semverTags) {
            return @()
        }
        
        # Sort by semantic version (custom sort to handle v prefix and pre-release)
        $sortedTags = $semverTags | Sort-Object {
            $version = $_ -replace '^v', ''
            
            # Split version and pre-release parts
            $parts = $version -split '-'
            $versionPart = $parts[0]
            $preReleasePart = if ($parts.Length -gt 1) { $parts[1] } else { "" }
            
            # Parse major.minor.patch
            $versionNumbers = $versionPart -split '\.'
            $major = [int]$versionNumbers[0]
            $minor = [int]$versionNumbers[1]
            $patch = [int]$versionNumbers[2]
            
            # Create sortable string (pre-release versions come after release versions)
            $sortKey = "{0:D10}.{1:D10}.{2:D10}" -f $major, $minor, $patch
            if ($preReleasePart) {
                $sortKey += ".0.$preReleasePart"  # Pre-release comes before release
            } else {
                $sortKey += ".1"  # Release version
            }
            
            return $sortKey
        } -Descending
        
        return $sortedTags
        
    } catch {
        Write-Warning "Error getting Git tags: $($_.Exception.Message)"
        return @()
    }
}