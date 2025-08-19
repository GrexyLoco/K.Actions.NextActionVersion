#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Quick test script for NextActionVersion module

.DESCRIPTION
    Tests the NextActionVersion module locally to ensure all functions work correctly
#>

Write-Host "🧪 Testing NextActionVersion Module..." -ForegroundColor Green

try {
    # Import the module
    Write-Host "📦 Importing module..." -ForegroundColor Cyan
    Import-Module "$PSScriptRoot\NextActionVersion.psm1" -Force
    Write-Host "✅ Module imported successfully" -ForegroundColor Green

    # Test basic functionality
    Write-Host "`n🔍 Testing version calculation..." -ForegroundColor Cyan
    $result = Get-NextActionVersion -RepoPath "." -BranchName "master"
    
    Write-Host "`n📊 Results:" -ForegroundColor Yellow
    Write-Host "  Current Version: $($result.CurrentVersion)" -ForegroundColor White
    Write-Host "  Bump Type: $($result.BumpType)" -ForegroundColor White
    Write-Host "  New Version: $($result.NewVersion)" -ForegroundColor White
    Write-Host "  Last Release Tag: $($result.LastReleaseTag)" -ForegroundColor White
    Write-Host "  Target Branch: $($result.TargetBranch)" -ForegroundColor White
    Write-Host "  Is First Release: $($result.IsFirstRelease)" -ForegroundColor White
    
    if ($result.Warning) {
        Write-Host "  ⚠️ Warning: $($result.Warning)" -ForegroundColor Yellow
    }
    
    if ($result.ActionRequired) {
        Write-Host "  ❗ Action Required: $($result.ActionInstructions)" -ForegroundColor Red
    }
    
    Write-Host "`n✅ Test completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "`n❌ Test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

Write-Host "`n🎯 NextActionVersion is ready to use!" -ForegroundColor Green