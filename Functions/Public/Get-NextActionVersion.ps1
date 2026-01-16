function Get-NextActionVersion {
    <#
    .SYNOPSIS
        Calculates the next semantic version for GitHub Actions based on Git tags and commit analysis
    
    .DESCRIPTION
        Analyzes Git repository to determine the next semantic version based on:
        - Latest Git tags (v1.0.0, 1.0.0, etc.)
        - Conventional commits since last tag (BumpType detection)
        - Branch-based PreRelease type (release/main/dev)
        - PreRelease lifecycle validation (Alpha→Beta→Stable)
        
        RELEASE BRANCHES (from unified Core.ps1):
        - release           → stable (no suffix)
        - main/master/staging → beta
        - dev/development   → alpha
        
        BUMPTYPE PATTERNS (commit-based only):
        - Major: BREAKING, MAJOR, !:, "breaking change"
        - Minor: FEATURE, MINOR, feat:, feat(, feature:, add:, new:
        - Patch: Everything else (default)
        
        PRERELEASE LIFECYCLE (one-way street):
        - Stable → Alpha/Beta (start new series)
        - Alpha → Beta (transition)
        - Alpha/Beta → Stable (release)
        - Beta → Alpha (FORBIDDEN)
    
    .PARAMETER RepoPath
        Path to Git repository root (default: current directory)
    
    .PARAMETER BranchName
        Current branch name for analysis and PreRelease type detection
    
    .PARAMETER TargetBranch
        Target branch for releases (auto-detected if not specified)
    
    .PARAMETER ForceFirstRelease
        Force first release even with unusual starting conditions
    
    .PARAMETER PreReleasePattern
        DEPRECATED: PreRelease is now determined by branch name, not pattern matching.
        Kept for backward compatibility but ignored.
    
    .EXAMPLE
        Get-NextActionVersion
        # Analyzes current repository and returns next version
    
    .EXAMPLE
        Get-NextActionVersion -BranchName "dev"
        # Returns alpha pre-release version (dev branch → alpha)
    
    .OUTPUTS
        PSCustomObject with properties:
        - CurrentVersion: Current version from latest tag
        - BumpType: major/minor/patch/none
        - NewVersion: Calculated new version
        - LastReleaseTag: Last Git tag found
        - TargetBranch: Target branch used
        - Suffix: Pre-release suffix (alpha/beta or empty)
        - Warning: Any warnings
        - ActionRequired: Whether manual action needed
        - ActionInstructions: Instructions for manual action
        - IsFirstRelease: Whether this is first release
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepoPath = ".",
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TargetBranch = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$ForceFirstRelease = $false,
        
        [Parameter(Mandatory = $false)]
        [string]$PreReleasePattern = "alpha|beta|rc|pre"  # DEPRECATED: Ignored
    )
    
    # Load unified Core.ps1 for branch-based PreRelease detection
    $corePath = Join-Path $PSScriptRoot "..\Private\SemanticVersioning.Core.ps1"
    if (Test-Path $corePath) {
        . $corePath
    }
    
    try {
        Write-Verbose "🔍 Analyzing Git repository for version calculation..."
        
        # Change to repository directory
        $originalLocation = Get-Location
        Set-Location $RepoPath
        
        # Auto-detect target branch if not specified
        if ([string]::IsNullOrEmpty($TargetBranch)) {
            $defaultBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
            if ($defaultBranch) {
                $TargetBranch = ($defaultBranch -split '/')[-1]
            } else {
                # Fallback detection
                $branches = @("main", "master")
                foreach ($branch in $branches) {
                    $exists = git show-ref --verify --quiet "refs/heads/$branch" 2>$null
                    if ($LASTEXITCODE -eq 0) {
                        $TargetBranch = $branch
                        break
                    }
                }
                if ([string]::IsNullOrEmpty($TargetBranch)) {
                    $TargetBranch = "main"  # Default fallback
                }
            }
        }
        
        Write-Verbose "📋 Target Branch: $TargetBranch"
        
        # Get current branch if not specified
        if ([string]::IsNullOrEmpty($BranchName)) {
            $BranchName = git rev-parse --abbrev-ref HEAD 2>$null
            if (-not $BranchName) {
                $BranchName = "unknown"
            }
        }
        
        Write-Verbose "🌿 Current Branch: $BranchName"
        
        # Check if branch is a release branch using unified Core.ps1 logic
        $branchInfo = if (Get-Command Get-ReleaseBranchInfo -ErrorAction SilentlyContinue) {
            Get-ReleaseBranchInfo -BranchName $BranchName
        } else {
            # Fallback if Core.ps1 not loaded
            [PSCustomObject]@{
                IsReleaseBranch = $BranchName -match '^(release|main|master|staging|dev|development)$'
                PreReleaseType = switch -Regex ($BranchName) {
                    '^release$' { $null }
                    '^(main|master|staging)$' { 'beta' }
                    '^(dev|development)$' { 'alpha' }
                    default { $null }
                }
                BranchName = $BranchName
            }
        }
        
        # Get latest Git tags
        $latestTag = Get-GitTags | Select-Object -First 1
        $allTags = Get-GitTags
        $isFirstRelease = $null -eq $latestTag
        
        if ($isFirstRelease) {
            Write-Warning "🆕 First release detected - no previous tags found"
            
            $currentVersion = "0.0.0"
            $newVersion = "1.0.0"  # Default first version for Actions
            $bumpType = "major"
            
            # Apply PreRelease suffix based on branch (unified logic)
            $suffix = $branchInfo.PreReleaseType
            if ($suffix) {
                $newVersion = "1.0.0-$suffix.1"
            }
            
            return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType $bumpType -NewVersion $newVersion -LastReleaseTag "" -TargetBranch $TargetBranch -Suffix $suffix -IsFirstRelease $true
        }
        
        Write-Verbose "🏷️ Latest tag: $latestTag"
        
        # Parse current version from tag
        $currentVersion = $latestTag -replace '^v', ''  # Remove 'v' prefix if present
        
        # Extract current PreRelease info from last tag
        $currentPreRelease = $null
        if ($currentVersion -match '^[\d\.]+-(alpha|beta)\.?\d*$') {
            $currentPreRelease = $matches[1]
        }
        
        # Get commits since latest tag
        $commitsSinceTag = Get-CommitsSinceTag -Tag $latestTag
        
        if ($commitsSinceTag.Count -eq 0) {
            Write-Verbose "✅ No commits since last tag - no version bump needed"
            return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType "none" -NewVersion $currentVersion -LastReleaseTag $latestTag -TargetBranch $TargetBranch -Suffix "" -IsFirstRelease $false
        }
        
        Write-Verbose "📝 Found $($commitsSinceTag.Count) commits since $latestTag"
        
        # Analyze commits for bump type (unified patterns)
        $bumpType = Get-BumpTypeFromCommits -Commits $commitsSinceTag -BranchName $BranchName
        
        Write-Verbose "⬆️ Detected bump type: $bumpType"
        
        # Validate PreRelease transition using unified Core.ps1 logic
        $targetPreRelease = $branchInfo.PreReleaseType
        $baseVersion = $currentVersion -replace '-.*$', ''  # Remove PreRelease suffix
        
        if (Get-Command Get-PreReleaseTransition -ErrorAction SilentlyContinue) {
            $transition = Get-PreReleaseTransition -CurrentPreRelease $currentPreRelease -TargetPreRelease $targetPreRelease -CurrentVersion $baseVersion
            
            if (-not $transition.IsValid) {
                return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType "none" -NewVersion $currentVersion -LastReleaseTag $latestTag -TargetBranch $TargetBranch -Suffix "" -Warning $transition.ErrorMessage -ActionRequired $true -ActionInstructions "PreRelease lifecycle violation: Cannot go from $currentPreRelease to $targetPreRelease" -IsFirstRelease $false
            }
            
            Write-Verbose "🔄 PreRelease transition: $($transition.Action)"
        }
        
        # Calculate new version based on transition type
        $newBaseVersion = Step-SemanticVersion -Version $baseVersion -BumpType $bumpType
        
        # Apply PreRelease suffix based on branch (unified logic)
        $suffix = $targetPreRelease
        if ($suffix) {
            # Calculate build number for PreRelease
            $buildNumber = 1
            if (Get-Command Get-NextBuildNumber -ErrorAction SilentlyContinue) {
                $buildNumber = Get-NextBuildNumber -BaseVersion $newBaseVersion -PreReleaseType $suffix -ExistingTags $allTags
            }
            $newVersion = "$newBaseVersion-$suffix.$buildNumber"
        } else {
            $newVersion = $newBaseVersion
        }
        
        Write-Verbose "🎯 New version: $newVersion"
        
        return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType $bumpType -NewVersion $newVersion -LastReleaseTag $latestTag -TargetBranch $TargetBranch -Suffix $suffix -IsFirstRelease $false
        
    } catch {
        Write-Error "❌ Error calculating version: $($_.Exception.Message)"
        return New-ActionVersionResult -CurrentVersion "0.0.0" -BumpType "none" -NewVersion "0.0.0" -LastReleaseTag "" -TargetBranch $TargetBranch -Suffix "" -Warning "Error: $($_.Exception.Message)" -ActionRequired $true -ActionInstructions "Please check repository state and try again" -IsFirstRelease $true
    } finally {
        Set-Location $originalLocation
    }
}