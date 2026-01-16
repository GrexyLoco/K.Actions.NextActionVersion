function Get-BumpTypeFromCommits {
    <#
    .SYNOPSIS
        Analyzes commit messages to determine semantic version bump type
    
    .DESCRIPTION
        Analyzes commit messages to determine appropriate version bump:
        - major: Breaking changes (BREAKING CHANGE:, major:, MAJOR:)
        - minor: New features (feat:, feature:, FEATURE:)
        - patch: Bug fixes and other changes (fix:, bugfix:, refactor:, etc.)
        
        NOTE: Branch-based BumpType detection has been REMOVED for consistency.
        Branch names like 'feature/xyz' don't logically determine version bumps.
        A patch release can come from any branch.
    
    .PARAMETER Commits
        Array of commit message strings
    
    .PARAMETER BranchName
        DEPRECATED: This parameter is ignored. Branch-based BumpType removed.
    
    .PARAMETER ConventionalCommits
        Whether to parse conventional commit format (always true now)
    
    .OUTPUTS
        String: "major", "minor", or "patch"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Commits,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName = "",  # DEPRECATED: Ignored, kept for backward compatibility
        
        [Parameter(Mandatory = $false)]
        [bool]$ConventionalCommits = $true  # Always true, kept for backward compatibility
    )
    
    $highestBump = "patch"  # Default to patch
    
    foreach ($commit in $Commits) {
        if ([string]::IsNullOrWhiteSpace($commit)) { continue }
        
        $commitLower = $commit.ToLower()
        $bumpType = "patch"  # Default for each commit
        
        # Check for breaking changes (highest priority)
        if ($commit -match "BREAKING[\s\-_]?CHANGE|MAJOR[\s:]" -or $commitLower -match "^(major|break)[\s:]") {
            $bumpType = "major"
        }
        # Check for features
        elseif ($commitLower -match "^(feat|feature)[\s:]") {
            $bumpType = "minor"
        }
        # Also check for uppercase keywords anywhere in commit (legacy support)
        elseif ($commit -match "BREAKING|MAJOR") {
            $bumpType = "major"
        }
        elseif ($commit -match "FEATURE|FEAT|MINOR") {
            $bumpType = "minor"
        }
        # Everything else stays at patch (including fix:, docs:, chore:, etc.)
        
        # Update highest bump type found
        if ($bumpType -eq "major") {
            return "major"  # Major is highest, can return immediately
        } elseif ($bumpType -eq "minor" -and $highestBump -ne "major") {
            $highestBump = "minor"
        }
    }
    
    # NOTE: Branch-based BumpType detection has been intentionally removed.
    # Reason: Branch names don't determine semantic impact. A patch can come from any branch.
    # This aligns with NextVersion and NextNetVersion behavior.
    
    return $highestBump
}
    return $highestBump
}