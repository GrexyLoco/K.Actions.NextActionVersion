# 🔄 Reusable Workflow - Next Action Version

> **📖 Vollständige Konzept-Dokumentation:** Siehe [K.Actions/REUSABLE-WORKFLOW-GUIDE.md](../../../../REUSABLE-WORKFLOW-GUIDE.md)  
> **Warum Reusable Workflows?** Caller-Context Problem, Private Repo Support, Migration - alles dort erklärt.

---

## 📋 Schnellstart

```yaml
jobs:
  version:
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

> **Note:** Conventional commits parsing (`feat:`, `fix:`, `BREAKING CHANGE:`) is always enabled (hardcoded).

---

## 🎯 Zweck

Semantic Versioning für **GitHub Actions**:
- Git Tag-basierte Versionierung
- Conventional Commits Parsing (`feat:`, `fix:`, `BREAKING CHANGE:`)
- Pre-Release Support (`alpha`, `beta`, `rc`, `pre`)
- Force First Release Logic

---

## 📥 Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `repo-path` | `'.'` | Path to repository root (for git operations) |
| `branch-name` | `github.ref_name` | Current branch name for analysis |
| `target-branch` | `''` (auto) | Target branch for release analysis (main/master) |
| `force-first-release` | `false` | Force first release even with unusual starting conditions |
| `pre-release-pattern` | `'alpha\|beta\|rc\|pre'` | Branch pattern for pre-release versions |
| `runs-on` | `'ubuntu-latest'` | Runner for version calculation |

---

## 📤 Outputs

| Output | Type | Description |
|--------|------|-------------|
| `current-version` | `string` | Current version from latest Git tag |
| `bump-type` | `string` | Detected version bump type (`major`/`minor`/`patch`/`none`) |
| `new-version` | `string` | Calculated new semantic version |
| `last-release-tag` | `string` | Last release tag found in repository |
| `target-branch` | `string` | Target branch used for analysis |

---

## 🚀 Vollständiges Beispiel

```yaml
name: Action Release Pipeline

on:
  push:
    branches: [master, main, develop]

jobs:
  calculate-version:
    name: 🔢 Semantic Versioning
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    with:
      force-first-release: false
      pre-release-pattern: 'alpha|beta|rc|develop'
      target-branch: 'main'
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}

  create-release:
    name: 📦 Create Release
    needs: calculate-version
    if: needs.calculate-version.outputs.bump-type != 'none'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      
      - name: 📊 Version Info
        run: |
          echo "Current: ${{ needs.calculate-version.outputs.current-version }}"
          echo "New: ${{ needs.calculate-version.outputs.new-version }}"
          echo "Bump: ${{ needs.calculate-version.outputs.bump-type }}"
      
      - name: 🏷️ Create Tag
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag "v${{ needs.calculate-version.outputs.new-version }}"
          git push --tags
```

---

## 📝 Conventional Commits

### Erkannte Patterns

```
feat: Add new feature          → Minor Bump (1.2.0 → 1.3.0)
fix: Fix bug                   → Patch Bump (1.2.0 → 1.2.1)
BREAKING CHANGE: ...           → Major Bump (1.2.0 → 2.0.0)
```

### Pre-Release Branches

```
Branch: develop    → 1.3.0-alpha.1
Branch: beta       → 1.3.0-beta.1
Branch: rc-1       → 1.3.0-rc.1
Branch: main       → 1.3.0 (stable)
```

---

## 💡 Best Practices

### 1. Conditional Release

```yaml
jobs:
  version:
    uses: .../next-action-version.yml@v1
    # ...
  
  release:
    needs: version
    # Nur bei echtem Bump
    if: needs.version.outputs.bump-type != 'none'
    runs-on: ubuntu-latest
    steps:
      - name: 📦 Create Release
        run: echo "Releasing v${{ needs.version.outputs.new-version }}"
```

### 2. Multi-Branch Strategy

```yaml
on:
  push:
    branches: [master, main, develop, beta]

jobs:
  version:
    uses: .../next-action-version.yml@v1
    with:
      pre-release-pattern: 'develop|beta|rc'
      target-branch: 'main'
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
  
  # develop → alpha releases
  # beta → beta releases
  # main → stable releases
```

---

## 🐛 Troubleshooting

### Error: "No tags found"

**Lösung:**
```yaml
with:
  force-first-release: true
```

### Error: "Invalid version format"

**Ursache:** Bestehende Tags folgen nicht Semantic Versioning (`vX.Y.Z`).

**Lösung:**
```bash
# Prüfe Tags
git tag -l

# Erstelle valide Tags
git tag v1.0.0
git push --tags
```

---

## 📚 Weiterführende Links

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
