function Get-NextActionVersion {
    <#
    .SYNOPSIS
        Calculates the next semantic version for GitHub Actions based on Git tags and commit analysis
    
    .DESCRIPTION
        Analyzes Git repository to determine the next semantic version based on:
        - Latest Git tags (v1.0.0, 1.0.0, etc.)
        - Conventional commits since last tag
        - Branch patterns and naming conventions
        - First release detection with default v1.0.0
    
    .PARAMETER RepoPath
        Path to Git repository root (default: current directory)
    
    .PARAMETER BranchName
        Current branch name for analysis
    
    .PARAMETER TargetBranch
        Target branch for releases (main/master, auto-detected if not specified)
    
    .PARAMETER ForceFirstRelease
        Force first release even with unusual starting conditions
    
    .PARAMETER ConventionalCommits
        Enable conventional commits parsing (feat:, fix:, BREAKING CHANGE:)
    
    .PARAMETER PreReleasePattern
        Pattern for pre-release branch detection (alpha|beta|rc|pre)
    
    .EXAMPLE
        Get-NextActionVersion
        # Analyzes current repository and returns next version
    
    .EXAMPLE
        Get-NextActionVersion -BranchName "feature/new-api" -ConventionalCommits $true
        # Analyzes feature branch with conventional commits
    
    .OUTPUTS
        PSCustomObject with properties:
        - CurrentVersion: Current version from latest tag
        - BumpType: major/minor/patch/none
        - NewVersion: Calculated new version
        - LastReleaseTag: Last Git tag found
        - TargetBranch: Target branch used
        - Suffix: Pre-release suffix
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
        [bool]$ConventionalCommits = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$PreReleasePattern = "alpha|beta|rc|pre"
    )
    
    try {
        Write-Host "🔍 Analyzing Git repository for version calculation..." -ForegroundColor Cyan
        
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
        
        Write-Host "📋 Target Branch: $TargetBranch" -ForegroundColor Green
        
        # Get current branch if not specified
        if ([string]::IsNullOrEmpty($BranchName)) {
            $BranchName = git rev-parse --abbrev-ref HEAD 2>$null
            if (-not $BranchName) {
                $BranchName = "unknown"
            }
        }
        
        Write-Host "🌿 Current Branch: $BranchName" -ForegroundColor Green
        
        # Get latest Git tags
        $latestTag = Get-GitTags | Select-Object -First 1
        $isFirstRelease = $null -eq $latestTag
        
        if ($isFirstRelease) {
            Write-Host "🆕 First release detected - no previous tags found" -ForegroundColor Yellow
            
            $currentVersion = "0.0.0"
            $newVersion = "1.0.0"  # Default first version for Actions
            $bumpType = "major"
            
            # Check for pre-release branch
            $suffix = ""
            if ($BranchName -match "($PreReleasePattern)") {
                $suffix = $matches[1]
                $newVersion = "1.0.0-$suffix.1"
            }
            
            return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType $bumpType -NewVersion $newVersion -LastReleaseTag "" -TargetBranch $TargetBranch -Suffix $suffix -IsFirstRelease $true
        }
        
        Write-Host "🏷️ Latest tag: $latestTag" -ForegroundColor Green
        
        # Parse current version from tag
        $currentVersion = $latestTag -replace '^v', ''  # Remove 'v' prefix if present
        
        # Get commits since latest tag
        $commitsSinceTag = Get-CommitsSinceTag -Tag $latestTag
        
        if ($commitsSinceTag.Count -eq 0) {
            Write-Host "✅ No commits since last tag - no version bump needed" -ForegroundColor Green
            return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType "none" -NewVersion $currentVersion -LastReleaseTag $latestTag -TargetBranch $TargetBranch -Suffix "" -IsFirstRelease $false
        }
        
        Write-Host "📝 Found $($commitsSinceTag.Count) commits since $latestTag" -ForegroundColor Cyan
        
        # Analyze commits for bump type
        $bumpType = Get-BumpTypeFromCommits -Commits $commitsSinceTag -BranchName $BranchName -ConventionalCommits $ConventionalCommits
        
        Write-Host "⬆️ Detected bump type: $bumpType" -ForegroundColor Yellow
        
        # Calculate new version
        $newVersion = Step-SemanticVersion -Version $currentVersion -BumpType $bumpType
        
        # Check for pre-release suffix
        $suffix = ""
        if ($BranchName -match "($PreReleasePattern)") {
            $suffix = $matches[1]
            $newVersion = "$newVersion-$suffix.1"
        }
        
        Write-Host "🎯 New version: $newVersion" -ForegroundColor Green
        
        return New-ActionVersionResult -CurrentVersion $currentVersion -BumpType $bumpType -NewVersion $newVersion -LastReleaseTag $latestTag -TargetBranch $TargetBranch -Suffix $suffix -IsFirstRelease $false
        
    } catch {
        Write-Host "❌ Error calculating version: $($_.Exception.Message)" -ForegroundColor Red
        return New-ActionVersionResult -CurrentVersion "0.0.0" -BumpType "none" -NewVersion "0.0.0" -LastReleaseTag "" -TargetBranch $TargetBranch -Suffix "" -Warning "Error: $($_.Exception.Message)" -ActionRequired $true -ActionInstructions "Please check repository state and try again" -IsFirstRelease $true
    } finally {
        Set-Location $originalLocation
    }
}