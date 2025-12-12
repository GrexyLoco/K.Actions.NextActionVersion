# 🔄 Reusable Workflow - Next Action Version

> **📖 Vollständige Konzept-Dokumentation:** Siehe [K.Actions/REUSABLE-WORKFLOW-GUIDE.md](../../../../REUSABLE-WORKFLOW-GUIDE.md)  
> **Warum Reusable Workflows?** Caller-Context Problem, Private Repo Support, Migration - alles dort erklärt.

---

## 📋 Schnellstart

### 🔍 Das Caller-Context Problem

**Zentrale Herausforderung:** Composite Actions laufen im **Caller-Repository Context**.

#### Was bedeutet das?

```
Caller-Repo (z.B. K.Actions.MyAction)
├── Eigene Dateien
└── Workflow-Ausführung
    └── Composite Action (K.Actions.NextActionVersion)
        ├── Läuft im CALLER-Dateisystem
        ├── Hat KEINE eigenen Dateien
        └── Sieht nur Caller-Repo Dateien
```

**Konsequenzen:**

1. **Kein Zugriff auf Action-Repo Dateien**
   - Action kann ihre eigenen Scripts nicht nutzen
   - Keine Hilfsdateien, Configs, Templates verfügbar
   - Alles muss im Caller-Repo existieren oder inline sein

2. **Manuelle Integration nötig**
   - Caller muss Action-Repo per `actions/checkout` holen
   - Caller muss korrekten Pfad kennen
   - Caller ist verantwortlich für korrektes Setup

3. **Private Repos = Extra Aufwand**
   - Standard `GITHUB_TOKEN` reicht nicht für fremde Repos
   - PAT mit `repo`-Scope erforderlich
   - Secret-Management für jeden Caller

#### Reusable Workflow löst das Problem

```
Action-Repo (K.Actions.NextActionVersion)
└── Reusable Workflow
    ├── Läuft im EIGENEN Job
    ├── Checkt BEIDE Repos aus
    │   ├── Caller-Repo (für Git History)
    │   └── Action-Repo (Versions-Logic)
    └── Kontrolliert kompletten Context
```

**Vorteile:**

1. **Selbstständig**: Workflow managed alle Checkouts
2. **Isoliert**: Klare Trennung zwischen Caller und Action
3. **Vollständig**: Zugriff auf alle Action-Dateien
4. **Sicher**: Kein PAT nötig bei same organization

### ✅ Vergleich

| Feature | Reusable Workflow | Composite Action |
|---------|------------------|------------------|
| **Private Repo Support** | ✅ Funktioniert mit Standard-Token | ❌ Benötigt PAT oder public |
| **Caller-Context Problem** | ✅ Eigener Job-Context | ❌ Läuft in Caller-Context |
| **Dateizugriff** | ✅ Beide Repos verfügbar | ⚠️ Nur Caller-Repo ohne Setup |
| **Maintenance** | ✅ Zentral verwaltbar | ⚠️ Jeder Caller muss updaten |
| **Secrets Handling** | ✅ Saubere Secret-Übergabe | ⚠️ Komplexer |
| **Setup-Aufwand** | ✅ 1 Zeile | ⚠️ 2-3 Steps pro Caller |
| **Debugging** | ✅ Klare Separation | ⚠️ Vermischter Context |
| **Flexibility** | ✅ Job-Level Konfiguration | ⚠️ Step-Level only |

### ❌ Warum nicht Composite Action bei privaten Repos?

**GitHub Actions Architektur-Limitation:**
- `uses: GrexyLoco/K.Actions.NextActionVersion@v1` funktioniert **nur** bei public repos
- Bei privaten Repos: **403 Forbidden** (auch mit PAT!)
- PAT ermöglicht nur `actions/checkout`, nicht direktes `uses:`
- Action läuft im Caller-Context → kein Zugriff auf eigene Dateien

**Workaround mit Composite Action:**
```yaml
# ⚠️ UMSTÄNDLICH - Jeder Caller muss zwei Steps haben
- uses: actions/checkout@v6
  with:
    repository: GrexyLoco/K.Actions.NextActionVersion
    token: ${{ secrets.PAT }}
    path: .github/actions/next-action-version

- uses: ./.github/actions/next-action-version
  with: ...
```

**Reusable Workflow löst das elegant:**
```yaml
# ✅ ELEGANT - Ein Call, alles erledigt
jobs:
  version:
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    with:
      conventional-commits: true
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}  # Kein PAT!
```

---

## 🚀 Integration: Reusable Workflow

### Minimales Beispiel

```yaml
name: Release Pipeline

on:
  push:
    branches: [master, main]

jobs:
  version:
    name: 🔢 Calculate Version
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Vollständiges Beispiel

```yaml
name: Action Release Pipeline

on:
  workflow_dispatch:
  push:
    branches: [master, main, develop]

jobs:
  calculate-version:
    name: 🔢 Semantic Versioning
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    with:
      repo-path: '.'
      conventional-commits: true
      force-first-release: false
      pre-release-pattern: 'alpha|beta|rc|pre'
      target-branch: 'main'
      runs-on: 'ubuntu-24.04'
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}

  create-release:
    name: 📦 Create Release
    needs: calculate-version
    runs-on: ubuntu-latest
    steps:
      - name: 📊 Version Info
        run: |
          echo "Current: ${{ needs.calculate-version.outputs.current-version }}"
          echo "New: ${{ needs.calculate-version.outputs.new-version }}"
          echo "Bump: ${{ needs.calculate-version.outputs.bump-type }}"
```

---

## 📥 Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `repo-path` | No | `'.'` | Path to repository root (for git operations) |
| `branch-name` | No | `github.ref_name` | Current branch name for analysis |
| `target-branch` | No | `''` (auto) | Target branch for release analysis (main/master) |
| `force-first-release` | No | `false` | Force first release even with unusual starting conditions |
| `conventional-commits` | No | `true` | Enable conventional commits parsing (feat:, fix:, BREAKING CHANGE:) |
| `pre-release-pattern` | No | `'alpha\|beta\|rc\|pre'` | Branch pattern for pre-release versions |
| `runs-on` | No | `'ubuntu-latest'` | Runner for version calculation |

### Secret

| Secret | Required | Description |
|--------|----------|-------------|
| `github-token` | **Yes** | GitHub Token für repository access |

**💡 Tipp:** Verwende `${{ secrets.GITHUB_TOKEN }}` - kein PAT nötig!

---

## 📤 Outputs

Alle Outputs sind verfügbar via `needs.<job-id>.outputs.*`:

| Output | Type | Description |
|--------|------|-------------|
| `current-version` | `string` | Current version from latest Git tag |
| `bump-type` | `string` | Detected version bump type (major/minor/patch/none) |
| `new-version` | `string` | Calculated new semantic version |
| `last-release-tag` | `string` | Last release tag found in repository |
| `target-branch` | `string` | Target branch used for analysis |

---

## 🔧 Technische Details

### Execution Flow

```
Caller Repo (z.B. K.Actions.MyAction)
    ↓
Ruft Reusable Workflow auf
    ↓
[Job: version]
├── Checkout 1: Caller Repo (für Git History & Tags)
├── Checkout 2: K.Actions.NextActionVersion (für action.yml)
└── Run: Lokale action.yml (./.github/actions/next-action-version)
    ├── Parse Git Tags
    ├── Analyze Commits (Conventional Commits)
    ├── Calculate Semantic Version
    └── Return Version Info
```

### Repository Context

- **Reusable Workflow Code**: Liegt in `K.Actions.NextActionVersion`
- **Execution Context**: Läuft im **Caller-Repo** (z.B. MyAction)
- **Filesystem**: Standard = Caller-Repo checkout (inkl. Git History)
- **Action Location**: Nach Checkout 2 in `.github/actions/next-action-version/`

### Private Repository Support

**Warum funktioniert das ohne PAT?**
- Reusable Workflows können andere private Repos in **derselben Organization** aufrufen
- Standard `GITHUB_TOKEN` hat automatisch Lesezugriff
- Gilt für: `workflow_call`, `actions/checkout`, Repository-Zugriffe

**Nicht unterstützt:**
- Direkte `uses:` für private Actions (GitHub Limitation)
- Cross-Organization private repos (benötigt PAT)
- Fine-grained tokens mit eingeschränkten Permissions

---

## 🔄 Migration von Composite Action

### Vorher (Composite Action mit PAT)

```yaml
jobs:
  version:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
      
      # ⚠️ MANUELLER CHECKOUT erforderlich
      - uses: actions/checkout@v6
        with:
          repository: GrexyLoco/K.Actions.NextActionVersion
          token: ${{ secrets.PRIVATE_ACTIONS_PAT }}
          path: .github/actions/next-action-version
      
      # Action aus lokalem Pfad
      - uses: ./.github/actions/next-action-version
        id: version
        with:
          conventionalCommits: true
```

### Nachher (Reusable Workflow)

```yaml
jobs:
  version:
    # ✅ ALLES IN EINEM - Kein manueller Checkout
    uses: GrexyLoco/K.Actions.NextActionVersion/.github/workflows/reusable/next-action-version.yml@v1
    with:
      conventional-commits: true
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

**Änderungen:**
- `jobs.<job-id>.steps` → `jobs.<job-id>.uses`
- Checkout-Steps entfallen komplett
- PAT nicht mehr benötigt
- Outputs via `needs.<job-id>.outputs.*` statt `steps.<step-id>.outputs.*`

---

## 📚 Best Practices

### 1. Semantic Versioning für Refs

```yaml
# ✅ EMPFOHLEN: Major Version Tag
uses: .../next-action-version.yml@v1

# ✅ GUT: Specific Version
uses: .../next-action-version.yml@v1.2.3

# ⚠️ MÖGLICH: Branch (instabil)
uses: .../next-action-version.yml@main

# ⚠️ MÖGLICH: Commit SHA (keine Updates)
uses: .../next-action-version.yml@abc123
```

### 2. Conditional Release

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

### 3. Pre-Release Branches

```yaml
jobs:
  version:
    uses: .../next-action-version.yml@v1
    with:
      conventional-commits: true
      pre-release-pattern: 'alpha|beta|rc|develop'
      target-branch: 'main'
    secrets:
      github-token: ${{ secrets.GITHUB_TOKEN }}
  
  # Branch 'develop' → pre-release version (e.g., 1.2.3-alpha.1)
  # Branch 'main' → stable version (e.g., 1.2.3)
```

---

## 🐛 Troubleshooting

### Error: "Resource not accessible by integration"

**Ursache:** `GITHUB_TOKEN` hat keine Berechtigung für private Repos.

**Lösung:**
```yaml
# Repository Settings → Actions → General → Workflow permissions
# ✅ Setze auf: "Read and write permissions"
```

### Error: "No tags found"

**Ursache:** Repository hat noch keine Git Tags.

**Lösung:**
```yaml
# Option 1: force-first-release verwenden
with:
  force-first-release: true

# Option 2: Manuell ersten Tag erstellen
git tag v0.1.0
git push --tags
```

### Error: "Invalid version format"

**Ursache:** Bestehende Tags folgen nicht Semantic Versioning (vX.Y.Z).

**Lösung:**
```bash
# Prüfe Tags
git tag -l

# Lösche ungültige Tags (Vorsicht!)
git tag -d <invalid-tag>
git push origin :refs/tags/<invalid-tag>

# Erstelle valide Tags
git tag v1.0.0
git push --tags
```

---

## 📖 Weiterführende Dokumentation

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions: Reusing Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)

---

## 🔄 Versions-Historie

### v1.0.0 (Current)
- ✅ Initiales Release mit Reusable Workflow
- ✅ Private Repository Support ohne PAT
- ✅ Vollständige Action-Integration
- ✅ Conventional Commits Support
- ✅ Pre-Release Pattern Matching

---

## 📧 Support

Bei Fragen oder Problemen:
1. Check [Troubleshooting](#-troubleshooting)
2. Review [GitHub Actions Logs](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/using-workflow-run-logs)
3. Open Issue im Repository

