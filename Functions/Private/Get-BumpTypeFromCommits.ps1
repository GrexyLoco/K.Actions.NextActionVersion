function Get-BumpTypeFromCommits {
    <#
    .SYNOPSIS
        Analyzes commit messages to determine semantic version bump type
    
    .DESCRIPTION
        Analyzes commit messages and branch name to determine appropriate version bump:
        - major: Breaking changes (BREAKING CHANGE:, major:, MAJOR:)
        - minor: New features (feat:, feature:, FEATURE:, feature/ branch)
        - patch: Bug fixes and other changes (fix:, bugfix:, refactor:, etc.)
    
    .PARAMETER Commits
        Array of commit message strings
    
    .PARAMETER BranchName
        Current branch name for pattern analysis
    
    .PARAMETER ConventionalCommits
        Whether to parse conventional commit format
    
    .OUTPUTS
        String: "major", "minor", or "patch"
    #>
    
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Commits,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$ConventionalCommits = $true
    )
    
    $highestBump = "patch"  # Default to patch
    
    foreach ($commit in $Commits) {
        $commitLower = $commit.ToLower()
        $bumpType = "patch"  # Default for each commit
        
        if ($ConventionalCommits) {
            # Check for breaking changes (highest priority)
            if ($commit -match "BREAKING[\s\-_]?CHANGE|MAJOR[\s:]" -or $commitLower -match "^(major|break)[\s:]") {
                $bumpType = "major"
            }
            # Check for features
            elseif ($commitLower -match "^(feat|feature)[\s:]") {
                $bumpType = "minor"
            }
            # Check for fixes (already default patch)
            elseif ($commitLower -match "^(fix|bugfix|patch|hotfix)[\s:]") {
                $bumpType = "patch"
            }
            # Check for other conventional commit types
            elseif ($commitLower -match "^(docs|style|refactor|test|chore)[\s:]") {
                $bumpType = "patch"
            }
        }
        
        # Also check for keywords anywhere in commit (legacy support)
        if ($commit -match "BREAKING|MAJOR") {
            $bumpType = "major"
        } elseif ($commit -match "FEATURE|FEAT|MINOR") {
            $bumpType = "minor"
        } elseif ($commit -match "FIX|BUGFIX|PATCH|HOTFIX") {
            $bumpType = "patch"
        }
        
        # Update highest bump type found
        if ($bumpType -eq "major") {
            $highestBump = "major"
        } elseif ($bumpType -eq "minor" -and $highestBump -ne "major") {
            $highestBump = "minor"
        }
    }
    
    # Analyze branch name for additional context
    if (-not [string]::IsNullOrEmpty($BranchName)) {
        $branchLower = $BranchName.ToLower()
        
        # Branch patterns can suggest bump type but don't override explicit commit messages
        if ($branchLower -match "^(major|breaking)" -and $highestBump -ne "major") {
            $highestBump = "major"
        } elseif ($branchLower -match "^(feature|feat)" -and $highestBump -eq "patch") {
            $highestBump = "minor"
        }
        # bugfix/, hotfix/, fix/ branches stay at patch level
    }
    
    return $highestBump
}