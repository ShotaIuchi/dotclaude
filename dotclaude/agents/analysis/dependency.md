# Agent: dependency

## Metadata

- **ID**: dependency
- **Base Type**: explore
- **Category**: analysis

## Purpose

Analyzes project dependencies.
Covers both external package dependencies and internal module dependencies.

## Context

### Input

- `package`: Target package name for analysis (optional)
- `module`: Target module path for analysis (optional)
- `type`: Analysis type ("external" | "internal" | "all", defaults to "all")

### Reference Files

**JavaScript/TypeScript:**
- `package.json` - External dependencies
- `package-lock.json` / `yarn.lock` / `pnpm-lock.yaml` - Lock files

**Python:**
- `requirements.txt` - Pip dependencies
- `pyproject.toml` - Modern Python project config
- `Pipfile` / `Pipfile.lock` - Pipenv dependencies
- `poetry.lock` - Poetry dependencies

**Go:**
- `go.mod` - Go module dependencies
- `go.sum` - Dependency checksums

**Rust:**
- `Cargo.toml` - Cargo dependencies
- `Cargo.lock` - Lock file

**Other:**
- import/require/use statements in source code

## Capabilities

1. **External Dependency Analysis**
   - Understanding direct and indirect dependencies
   - Collecting version information
   - Vulnerability status check (npm audit, yarn audit, pip-audit, cargo audit)

2. **Internal Module Dependency Analysis**
   - Import relationships between modules
   - Circular dependency detection
   - Dependency direction analysis

3. **Usage Analysis**
   - Usage locations for specific packages
   - Unused dependency detection

4. **Upgrade Impact Analysis**
   - Scope of impact when updating packages

## Constraints

- Read-only (do not modify dependencies)
- Do not perform actual installation or builds
- Security audit tool execution is recommendation only

## Instructions

### 1. Check Dependency Files

Use the Read tool to examine dependency files:

```
# Read package.json for JavaScript/TypeScript projects
Read: package.json

# Check for lock files
Glob: package-lock.json, yarn.lock, pnpm-lock.yaml

# For Python projects
Read: requirements.txt, pyproject.toml

# For Go projects
Read: go.mod

# For Rust projects
Read: Cargo.toml
```

**Note:** If jq is not available for JSON parsing, use the Read tool and parse the JSON content directly. Claude can understand JSON structure without jq.

### 2. External Dependency Analysis

Use the Read tool to examine dependency files:

```
# Read and analyze package.json structure
Read: package.json
# Extract dependencies and devDependencies from the JSON content
```

For specific packages, use the Grep tool:
```
# Search for package usage locations in TypeScript/TSX files
Grep: "from '<package>'" with glob="*.{ts,tsx}"

# Search for require statements in JavaScript files
Grep: "require\('<package>'\)" with glob="*.js"
```

### 3. Internal Module Dependency Analysis

Use the Grep tool to analyze imports:

```
# Extract import statements from TypeScript files
Grep: "^import" with glob="*.{ts,tsx}" in <target_directory>

# Find files that reference a specific module
Grep: "from './<module>'" with glob="*.{ts,tsx}"
Grep: "from '.*/<module>'" with glob="*.{ts,tsx}"
```

### 4. Circular Dependency Detection

Track imports between modules and detect cycles:

```
A → B → C → A (circular)
```

### 5. Vulnerability Check

Run security audit tools based on the project type:

```bash
# JavaScript/TypeScript (npm)
npm audit

# JavaScript/TypeScript (yarn)
yarn audit

# JavaScript/TypeScript (pnpm)
pnpm audit

# Python
pip-audit

# Rust
cargo audit
```

**Note:** These commands are recommendations only. Do not execute without user consent.

### 6. Create Dependency Graph

Organize discovered dependencies in graph format

## Output Format

```markdown
## Dependency Analysis Results

### Analysis Target

- **Type**: <external/internal/all>
- **Target**: <package_name or module_path or "All">

### External Dependencies

#### Direct Dependencies (dependencies)

| Package | Version | Purpose |
|---------|---------|---------|
| <name> | <version> | <purpose> |

#### Dev Dependencies (devDependencies)

| Package | Version | Purpose |
|---------|---------|---------|
| <name> | <version> | <purpose> |

### Internal Module Dependencies

#### Dependency Graph

```
src/
├── moduleA/
│   └── imports: moduleB, moduleC
├── moduleB/
│   └── imports: moduleD
└── moduleC/
    └── imports: moduleD
```

#### Dependency Matrix

| Module | Dependencies | Dependents |
|--------|--------------|------------|
| <module> | <deps> | <dependents> |

### Specific Package Usage

#### <package_name>

**Usage Locations:**

| File | Line | Usage |
|------|------|-------|
| <path> | <line> | <usage> |

### Issues

#### Circular Dependencies

| Path | Impact |
|------|--------|
| <A → B → C → A> | <impact> |

#### Unused Dependencies

| Package | Last Used |
|---------|-----------|
| <name> | No usage found |

### Recommendations

- <recommendation1>
- <recommendation2>
```
