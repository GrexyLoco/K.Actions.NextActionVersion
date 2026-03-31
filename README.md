# K.Actions.NextActionVersion

<!-- AUTO-GENERATED BADGES - DO NOT EDIT MANUALLY -->
## 📊 Status

![Quality Gate](https://img.shields.io/badge/Quality_Gate-passing-brightgreen?logo=githubactions) ![Release](https://img.shields.io/badge/Release-none-lightgrey?logo=github) [![CI](https://github.com/GrexyLoco/K.Actions.NextActionVersion/actions/workflows/release.yml/badge.svg)](https://github.com/GrexyLoco/K.Actions.NextActionVersion/actions/workflows/release.yml)

> 🕐 **Last Updated:** 2026-03-31 07:44:08 UTC | **Action:** `Next Action Version`
<!-- END AUTO-GENERATED BADGES -->

🚀 **Intelligent version management for GitHub Actions** - automatically calculates next semantic version based on conventional commits and Git tags

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/release/GrexyLoco/K.Actions.NextActionVersion.svg)](https://github.com/GrexyLoco/K.Actions.NextActionVersion/releases)

## 🎯 Purpose

**NextActionVersion** calculates semantic versions for **GitHub Actions** based purely on **Git tags and commit analysis**.

### Key Characteristics:
- ✅ **100% Git tag-based** - no manifest file dependencies
- ✅ First release defaults to **v1.0.0** when no tags exist
- ✅ Analyzes commits since latest tag for bump type
- ✅ Supports conventional commits (`feat:`, `fix:`, `BREAKING CHANGE:`)
- ✅ Branch pattern analysis (`feature/`, `bugfix/`, `major/`)

### 📚 Compare: K.Actions.NextVersion vs. K.Actions.NextActionVersion

⚠️ **IMPORTANT:** Both actions work identically - they analyze **Git tags only**!

| Feature | **K.Actions.NextVersion** | **K.Actions.NextActionVersion** |
|---------|---------------------------|----------------------------------|
| **Primary Use Case** | PowerShell Modules | GitHub Actions |
| **Version Source** | Git tags only | Git tags only |
| **First Release Default** | v1.0.0 (if no tags) | v1.0.0 (if no tags) |
| **PSD1 Reading** | ❌ No (.psd1 not used for versioning) | ❌ No |
| **Commit Analysis** | ✅ Conventional commits + branch patterns | ✅ Conventional commits + branch patterns |
| **Pre-Release** | `-alpha`, `-beta`, `-rc` | `-alpha`, `-beta`, `-rc` |
| **Recommended For** | K.PSGallery.* modules | K.Actions.* repositories |

**The Difference:**
- **Naming convention only** - helps identify target project type
- **NextVersion** → Suggested for PowerShell modules (but works for any Git repo)
- **NextActionVersion** → Suggested for GitHub Actions (but works for any Git repo)
- **Both read Git tags exclusively** - no manifest parsing

**Example Decision Tree:**
```
What type of project?
├── PowerShell Module → Use K.Actions.NextVersion (convention)
│   └── Still uses Git tags (not .psd1) for versioning
└── GitHub Action → Use K.Actions.NextActionVersion (convention)
    └── Uses Git tags for versioning
```

## 🌟 Features

- **🏷️ Git Tag-Based:** Uses Git tags as **single source of truth** (no .psd1 dependency)
- **📝 Conventional Commits:** Supports conventional commit format (`feat:`, `fix:`, `BREAKING CHANGE:`)
- **🌿 Branch Analysis:** Analyzes branch patterns (`feature/`, `bugfix/`, `major/`)
- **🆕 First Release Smart:** Defaults to **v1.0.0** for new Actions (GitHub Actions standard)
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
| `preReleasePattern` | (Legacy/Ignored) Pre-release type is now determined by branch name | ❌ | `alpha\|beta\|rc\|pre` |

> **Note:** Conventional commits parsing (`feat:`, `fix:`, `BREAKING CHANGE:`) is always enabled (hardcoded).

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
      - uses: actions/checkout@v6
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
    
# On feature/new-api branch -> 1.3.0-alpha1
# On beta/testing branch -> 1.3.0-beta1
```

## 🧠 Version Calculation Logic

### **Git Tag Analysis**
1. Finds latest semantic version tag (`v1.0.0`, `1.0.0`)
2. Analyzes commits since tag
3. Determines bump type from commits + branch

### **Conventional Commits Support**
| Commit Format | Bump Type | Example |
|---------------|-----------|---------|
| `BREAKING`, `MAJOR`, `!:`, `"breaking change"` | **Major** | `BREAKING: Remove deprecated API`, `feat!: redesign API` |
| `FEATURE`, `MINOR`, `feat:`, `feat(`, `feature:`, `add:`, `new:` | **Minor** | `feat: add authentication`, `FEATURE: New endpoint` |
| *(default)* | **Patch** | All other commits |

### **Release Branches (PreRelease-Source)**
| Branch Pattern | PreRelease | Description |
|---------------|------------|-------------|
| `release`, `release/*` | *(none)* | Stable Release |
| `main`, `master`, `staging` | `beta` | Beta Version |
| `dev`, `develop`, `development` | `alpha` | Alpha Version |
| Other | *(none)* | Not versioned (no pre-release) |

### **PreRelease-Lifecycle**
PreRelease transitions follow a strict **one-way-street**:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   STABLE    │────▶│    ALPHA    │────▶│    BETA     │
│  (release)  │     │    (dev)    │     │   (main)    │
└─────────────┘     └─────────────┘     └─────────────┘
      ▲                                        │
      │                                        │
      └────────────────────────────────────────┘
               Only forward allowed!
```

**Allowed:** `Stable → Alpha → Beta → Stable`, `Stable → Beta` (directly)  
**Forbidden:** `Beta → Alpha`

### **Build-Number**
Within a PreRelease series, the build number is automatically incremented:

```
1.0.0-alpha.1 → 1.0.0-alpha.2 → 1.0.0-alpha.3 → 1.0.0-beta.1 → 1.0.0
```

### **Branch Pattern Analysis (Legacy)**
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

**Truth: Both actions are functionally identical!**

| Aspect | Reality |
|--------|---------|
| **Version Source** | Both use **Git tags only** (no .psd1 parsing) |
| **First Release** | Both default to **v1.0.0** when no tags exist |
| **Commit Analysis** | Both use conventional commits + branch patterns |
| **Pre-Release** | Both support `-alpha`, `-beta`, `-rc` suffixes |
| **Code Logic** | Identical Git tag-based version calculation |

**The Only Difference:**
- **Naming convention** to indicate intended project type
- **NextVersion** → Suggested for PowerShell modules
- **NextActionVersion** → Suggested for GitHub Actions
- **Both work for any Git repository** - no technical differences

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