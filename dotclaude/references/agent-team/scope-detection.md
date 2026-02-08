# Agent Team Scope Detection

Common reference for parsing `$ARGUMENTS` in all Agent Team skills.
The Lead Agent must resolve the analysis target before spawning any sub-agents.

## Supported Scopes

| Scope | Flag | Retrieval Command | Example |
|-------|------|-------------------|---------|
| PR | `--pr <N>` | `gh pr diff <N>` + `gh pr view <N> --json title,body,files` | `/team-review --pr 42` |
| Issue | `--issue <N>` | `gh issue view <N> --json title,body,comments` | `/team-debug --issue 123` |
| Commit | `--commit <ref>` | `git show <ref>` or `git diff <A>..<B>` | `/team-review --commit HEAD~3..HEAD` |
| Staged diff | `--staged` | `git diff --staged` | `/team-review --staged` |
| Unstaged diff | `--diff` | `git diff` | `/team-test --diff` |
| Branch diff | `--branch <name>` | `git diff main...<name>` | `/team-review --branch feature/auth` |
| File/Directory | path (auto-detect) | `Read` / `Glob` | `/team-test src/auth/` |
| Free text | (residual) | Use as instruction/context | `/team-debug login fails on timeout` |

## Auto-Detection Rules (when no flag is given)

Apply in order; stop at the first match:

```
1. --flag present       -> Follow the flag (highest priority)
2. Path-like string     -> File/Directory (contains `.` or `/`)
3. Bare number          -> AMBIGUOUS: ask user (PR / Issue / other)
4. Other text           -> Free text (use as instruction)
5. Empty                -> UNKNOWN: ask user to specify target
```

## Ambiguous / Empty Input Handling

When the input is empty or ambiguous, the Lead Agent MUST present a prompt:

```
Please specify the target:
- PR number (e.g., --pr 42)
- Issue number (e.g., --issue 123)
- Commit (e.g., --commit HEAD~3..HEAD)
- Current diff (--diff / --staged)
- Branch diff (e.g., --branch feature/auth)
- File path (e.g., src/auth/)
```

### Bare-Number Disambiguation

When the argument is a bare number (e.g., `42`), the Lead Agent MUST ask:

```
"42" could refer to multiple targets. Which do you mean?
- PR #42       (--pr 42)
- Issue #42    (--issue 42)
- Something else (please specify)
```

## Flag Parsing Rules

- Flags are case-sensitive and use `--` prefix
- A flag consumes the next whitespace-separated token as its value (except `--diff` and `--staged` which are boolean)
- Unknown flags are treated as free text
- Multiple flags can be combined: `--pr 42 --commit HEAD~3..HEAD` (PR is primary scope)
- Remaining tokens after flag parsing become the free-text context

## Integration with Team Skills

Each team SKILL.md includes a **Step 0: Scope Detection** phase that references this document.
The Lead Agent completes Step 0 before proceeding to the team-specific analysis (Step 1).
