# K.Actions.NextActionVersion

🚀 **Intelligent version management for GitHub Actions** - automatically calculates next semantic version based on conventional commits and Git tags

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/GrexyLoco/K.Actions.NextActionVersion.svg)](https://github.com/GrexyLoco/K.Actions.NextActionVersion/releases)

## 🌟 Features

- **🏷️ Git Tag-Based:** Uses Git tags as single source of truth for versioning
- **📝 Conventional Commits:** Supports conventional commit format (`feat:`, `fix:`, `BREAKING CHANGE:`)
- **🌿 Branch Analysis:** Analyzes branch patterns (`feature/`, `bugfix/`, `major/`)
- **🆕 First Release Smart:** Defaults to v1.0.0 for new Actions (no .psd1 dependency)
- **🎭 Pre-Release Support:** Alpha/beta/rc versions for feature branches
- **🔧 Auto-Discovery:** Automatically detects main/master branch
- **⚡ Fast & Lightweight:** Pure PowerShell, no external dependencies

## 📋 Inputs

| Parameter | Description | Required | Default |
|-----------|-------------|----------|---------|
| `repoPath` | Repository root path | ❌ | `.` |
| `branchName` | Current branch name | ❌ | `${{ github.ref_name }}` |
| `targetBranch` | Target branch for releases | ❌ | Auto-discovery |
| `forceFirstRelease` | Force first release | ❌ | `false` |
| `conventionalCommits` | Enable conventional commits | ❌ | `true` |
| `preReleasePattern` | Pre-release branch pattern | ❌ | `alpha\|beta\|rc\|pre` |

## 📊 Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `currentVersion` | Current version from latest tag | `1.2.3` |
| `bumpType` | Version bump type | `major/minor/patch/none` |
| `newVersion` | Calculated new version | `1.3.0` |
| `lastReleaseTag` | Last Git tag found | `v1.2.3` |
| `targetBranch` | Target branch used | `main` |
| `suffix` | Pre-release suffix | `alpha/beta/rc` |
| `warning` | Warning message | `""` |
| `actionRequired` | Manual action needed | `false` |
| `actionInstructions` | Instructions | `""` |
| `isFirstRelease` | First release flag | `false` |

## 🚀 Usage Examples

### **Basic Usage**
```yaml
- name: Calculate Next Version
  id: version
  uses: GrexyLoco/K.Actions.NextActionVersion@v1
  
- name: Display Version
  run: |
    echo "Current: ${{ steps.version.outputs.currentVersion }}"
    echo "New: ${{ steps.version.outputs.newVersion }}"
    echo "Bump: ${{ steps.version.outputs.bumpType }}"
```

### **Complete Release Workflow**
```yaml
name: Release Action

on:
  push:
    branches: [main, master]

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Required for Git history analysis
      
      - name: Calculate Next Version
        id: version
        uses: GrexyLoco/K.Actions.NextActionVersion@v1
        
      - name: Skip if no changes
        if: steps.version.outputs.bumpType == 'none'
        run: |
          echo "No version changes detected - skipping release"
          exit 0
          
      - name: Create Release Tag
        if: steps.version.outputs.bumpType != 'none'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag "v${{ steps.version.outputs.newVersion }}"
          git push origin "v${{ steps.version.outputs.newVersion }}"
          
      - name: Create GitHub Release
        if: steps.version.outputs.bumpType != 'none'
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ steps.version.outputs.newVersion }}
          release_name: Release v${{ steps.version.outputs.newVersion }}
          draft: false
          prerelease: ${{ contains(steps.version.outputs.newVersion, '-') }}
```

### **Pre-Release Workflow**
```yaml
- name: Calculate Pre-Release Version
  id: version
  uses: GrexyLoco/K.Actions.NextActionVersion@v1
  with:
    preReleasePattern: "alpha|beta|rc|preview"
    
# On feature/new-api branch -> 1.3.0-alpha.1
# On beta/testing branch -> 1.3.0-beta.1
```

## 🧠 Version Calculation Logic

### **Git Tag Analysis**
1. Finds latest semantic version tag (`v1.0.0`, `1.0.0`)
2. Analyzes commits since tag
3. Determines bump type from commits + branch

### **Conventional Commits Support**
| Commit Format | Bump Type | Example |
|---------------|-----------|---------|
| `feat:` | **Minor** | `feat: add new authentication` |
| `fix:` | **Patch** | `fix: resolve memory leak` |
| `BREAKING CHANGE:` | **Major** | `feat!: redesign API` |
| `docs:`, `style:`, `refactor:` | **Patch** | `docs: update README` |

### **Branch Pattern Analysis**
| Branch Pattern | Bump Type | Example |
|----------------|-----------|---------|
| `feature/*` | **Minor** | `feature/user-dashboard` |
| `bugfix/*`, `fix/*` | **Patch** | `bugfix/memory-leak` |
| `major/*`, `breaking/*` | **Major** | `major/api-redesign` |
| `alpha/*`, `beta/*` | **Pre-release** | `alpha/experimental` |

### **First Release Behavior**
- **No tags found:** Defaults to `v1.0.0`
- **No .psd1 dependency:** Pure Git-based versioning
- **Smart detection:** Works with any Action repository

## 🔄 Differences from K.Actions.NextVersion

| Feature | NextVersion (Modules) | NextActionVersion (Actions) |
|---------|----------------------|----------------------------|
| **Source of Truth** | `.psd1` ModuleVersion | Git Tags |
| **First Release** | Uses .psd1 version | Defaults to v1.0.0 |
| **Target Use** | PowerShell Modules | GitHub Actions |
| **Dependencies** | Requires .psd1 file | Pure Git repository |
| **Version Format** | Module semantic versioning | Action semantic versioning |

## 🔧 Local Testing

```powershell
# Clone and test locally
git clone https://github.com/GrexyLoco/K.Actions.NextActionVersion
cd K.Actions.NextActionVersion

# Import module
Import-Module .\NextActionVersion.psm1 -Force

# Test version calculation
$result = Get-NextActionVersion -RepoPath "." -BranchName "main"
Write-Host "Next version: $($result.NewVersion)"
```

## 📝 Best Practices

1. **Use Conventional Commits:** Clear commit messages improve version accuracy
2. **Semantic Branching:** Use standard branch patterns (`feature/`, `bugfix/`)
3. **Fetch Full History:** Use `fetch-depth: 0` in checkout action
4. **Tag Consistently:** Use `v1.0.0` format for tags
5. **Test Locally:** Validate version calculation before CI/CD

## 🔗 Related Projects

- [K.Actions.NextVersion](https://github.com/GrexyLoco/K.Actions.NextVersion) - For PowerShell Modules
- [K.Actions.PSModuleValidation](https://github.com/GrexyLoco/K.Actions.PSModuleValidation) - Module Testing
- [Semantic Versioning](https://semver.org/) - Versioning Standard

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -am 'feat: add amazing feature'`
4. Push branch: `git push origin feature/amazing-feature`
5. Submit Pull Request

## 📞 Support

- 🐛 [Report Issues](https://github.com/GrexyLoco/K.Actions.NextActionVersion/issues)
- 💡 [Feature Requests](https://github.com/GrexyLoco/K.Actions.NextActionVersion/issues)
- 📖 [Documentation](https://github.com/GrexyLoco/K.Actions.NextActionVersion/wiki)

---

**🎯 Made for GitHub Actions | 🚀 Powered by Semantic Versioning | ⚡ Zero Dependencies**