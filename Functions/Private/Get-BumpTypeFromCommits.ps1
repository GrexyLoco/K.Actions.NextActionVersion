function Get-BumpTypeFromCommits {
    <#
    .SYNOPSIS
        Analyzes commit messages to determine semantic version bump type
    
    .DESCRIPTION
        Analyzes commit messages to determine appropriate version bump:
        - major: Breaking changes (BREAKING, MAJOR, !:, "breaking change")
        - minor: New features (FEATURE, MINOR, feat:, feat(, feature:, add:, new:)
        - patch: Bug fixes and other changes (default)
        
        NOTE: Branch-based BumpType detection has been REMOVED for consistency.
        Branch names like 'feature/xyz' don't logically determine version bumps.
        A patch release can come from any branch.
        
        PATTERNS (identical to NextVersion and NextNetVersion):
        Major: BREAKING, MAJOR, !:, "breaking change" (case-insensitive)
        Minor: FEATURE, MINOR, feat:, feat(, feature:, add:, new: (case-insensitive)
    
    .PARAMETER Commits
        Array of commit message strings
    
    .PARAMETER BranchName
        DEPRECATED: This parameter is ignored. Branch-based BumpType removed.
    
    .PARAMETER ConventionalCommits
        DEPRECATED: Always true now, kept for backward compatibility
    
    .OUTPUTS
        String: "major", "minor", or "patch"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Commits,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName = "",  # DEPRECATED: Ignored
        
        [Parameter(Mandatory = $false)]
        [bool]$ConventionalCommits = $true  # DEPRECATED: Always true
    )
    
    # Unified BumpType patterns (identical to NextVersion Core.ps1)
    $majorPatterns = @(
        'BREAKING'           # BREAKING: or BREAKING CHANGE
        'MAJOR'              # MAJOR: explicit major bump
        '!:'                 # feat!: breaking feature (conventional commits)
        'breaking change'    # breaking change in message (case-insensitive)
    )
    $minorPatterns = @(
        'FEATURE'            # FEATURE: new feature
        'MINOR'              # MINOR: explicit minor bump
        'feat:'              # feat: conventional commit
        'feat('              # feat(scope): conventional commit
        'feature:'           # feature: new feature
        'add:'               # add: new addition
        'new:'               # new: new functionality
    )
    
    $highestBump = "patch"  # Default to patch
    
    foreach ($commit in $Commits) {
        if ([string]::IsNullOrWhiteSpace($commit)) { continue }
        
        $commitLower = $commit.ToLower()
        
        # Check for MAJOR indicators (case-sensitive for uppercase keywords)
        foreach ($pattern in $majorPatterns) {
            $patternLower = $pattern.ToLower()
            if ($commit -match [regex]::Escape($pattern) -or $commitLower -match [regex]::Escape($patternLower)) {
                return "major"  # Major is highest, return immediately
            }
        }
        
        # Check for MINOR indicators
        foreach ($pattern in $minorPatterns) {
            $patternLower = $pattern.ToLower()
            if ($commit -match [regex]::Escape($pattern) -or $commitLower -match [regex]::Escape($patternLower)) {
                $highestBump = "minor"  # Continue checking for major
                break
            }
        }
    }
    
    return $highestBump
}