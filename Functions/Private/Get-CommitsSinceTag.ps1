function Get-CommitsSinceTag {
    <#
    .SYNOPSIS
        Gets commit messages since specified Git tag
    
    .DESCRIPTION
        Retrieves all commit messages from specified tag to HEAD
        Useful for analyzing changes for version bump calculation
    
    .PARAMETER Tag
        Git tag to compare against
    
    .OUTPUTS
        Array of commit message strings
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag
    )
    
    try {
        # Get commit messages since tag
        $commits = git log "$Tag..HEAD" --pretty=format:"%s" 2>$null
        if ($LASTEXITCODE -ne 0) {
            return @()
        }
        
        # Convert to array and filter empty lines
        $commitArray = @()
        if ($commits) {
            $commitArray = $commits -split "`n" | Where-Object { $_.Trim() -ne "" }
        }
        
        return $commitArray
        
    } catch {
        Write-Warning "Error getting commits since tag '$Tag': $($_.Exception.Message)"
        return @()
    }
}