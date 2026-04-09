---
name: pr-comment-fix
description: >
  PRのレビュー指摘コメントを取得・評価し、修正すべきものを修正してコミット・プッシュまで自動化するスキル。
  「PRコメント対応」「PR指摘修正」「レビュー指摘の取り込み」「pr fix」「pr comment fix」
  「レビューコメントを反映」「指摘を取り込んで」等で起動する。
  定期実行用の自動モード（`--auto` または `auto`）と、ユーザーによる単独実行モードの両方に対応。
  自動モードでは一切確認せず、手動モードでも本当に判断不能な場合のみ確認する。
argument-hint: [<PR number or URL>] [--auto] [--repo] [--author <login>]... [--include-drafts]
---

# pr-comment-fix: PR Review Comment Auto-Fix

Fetches review comments from a pull request, evaluates each one, applies fixes for the actionable ones, commits via the `commit` skill, and pushes the result. Designed to run both as a scheduled background task (auto mode) and as a user-invoked workflow.

## Mode Detection

This skill has two execution modes — they share the same workflow but differ in how they handle ambiguity.

| Mode | Trigger | Behavior |
|------|---------|----------|
| **auto** | `$ARGUMENTS` contains `--auto` or the bare word `auto` | Never ask the user anything. Resolve every ambiguity autonomously using the safest reasonable choice. |
| **manual** | Default (no auto flag) | Run autonomously by default. Only ask the user when a decision genuinely cannot be made without their judgment (e.g., a comment proposes two contradictory designs). |

Strip the auto flag from `$ARGUMENTS` before parsing the rest. Other recognized flags are described in Step 1 (`--repo`, `--author <login>` repeatable, `--include-drafts`).

## Step 1 — Identify the Target PR(s)

This skill supports four targeting modes. Determine which one applies from the remaining arguments, then build a list of PRs to process.

### Targeting modes

| Mode | Trigger | PRs processed |
|------|---------|---------------|
| **single** | A PR number, `#N`, or pull request URL is given | Just that one PR |
| **repo** | `--repo` flag is given (and no specific PR identifier) | All open PRs in the current repository |
| **branch** | No PR identifier and no `--repo` flag | The PR associated with the current branch (if any) |
| **filtered repo** | `--repo` plus one or more `--author <login>` flags | All open PRs in the repo authored by any of the listed users |

`--author` can be specified multiple times to allow several users (e.g. `--author alice --author bob`). Authors are matched against the PR's `author.login` field.

### Natural-language arguments

`$ARGUMENTS` does not have to use the strict flag form. Parse natural language too — the user may say things like:

- `自分のPRだけ` / `me` / `私の` / `my prs` → resolve to the current user's GitHub login via `gh api user --jq .login`, then treat as `--author <login>`
- `aliceとbobのPR` / `alice and bob` → extract `alice`, `bob` as authors
- `リポジトリ全体` / `all open PRs` / `repo` → set repo mode
- `ドラフトも含めて` / `include drafts` → set `--include-drafts`
- `#123` / `PR 123` / `the auth PR` → single mode; for vague references like "the auth PR", run `gh pr list` and pick the best match by title, but in **auto mode** prefer to fail rather than guess

When natural language is used, **echo back the resolved scope** at the start of the run so the user can see how it was interpreted (e.g., `Scope: repo, authors=[shotaiuchi, alice], drafts=excluded`). In **manual mode**, if the interpretation is genuinely ambiguous, ask before proceeding; in **auto mode**, pick the most conservative interpretation and log it.

The `--include-drafts` flag controls whether draft PRs are processed. **Default: drafts are excluded.** When `--include-drafts` is set, drafts are treated identically to ready PRs. This applies to all modes except **single** — when a user explicitly names a single PR, process it regardless of draft state (the explicit reference is intent enough).

### Listing PRs for repo / filtered-repo / branch modes

Use `gh pr list` with the appropriate filters. Include the fields needed downstream:

```bash
gh pr list \
  --state open \
  --json number,headRefName,baseRefName,url,isDraft,author,title \
  --limit 100
```

Then in code:
- Filter out drafts unless `--include-drafts` is set
- Filter by `author.login ∈ <author list>` if `--author` flags were given
- For **branch** mode, restrict to PRs whose `headRefName` matches the current branch

If the resulting list is empty:
- **auto mode**: log the scope (e.g., `pr-comment-fix: 0 open PRs in scope (repo=<repo>, authors=<list>, drafts=<bool>)`) and exit cleanly. This is the normal "nothing to do" outcome for cron runs.
- **manual mode**: report the empty result and stop. Do not silently widen the filters.

### Single mode: parsing the identifier

| Input | Action |
|-------|--------|
| `123` or `#123` | Use PR number `123` in the current repo |
| `https://github.com/owner/repo/pull/123` | Extract owner, repo, and number from URL |

For each PR in scope, capture its metadata (head ref, base ref, repo, draft state, author) — you'll need these for fetching comments, switching branches, and pushing.

### Processing multiple PRs

When the scope yields more than one PR, process them **sequentially**, not in parallel — each PR involves checking out its branch, applying fixes, committing, and pushing, and parallelizing those would scramble the working tree. For each PR:

1. Check out the PR branch: `gh pr checkout <number>` (this creates / updates a local branch tracking the PR head)
2. Run Steps 2–8 of this skill against that single PR
3. After Step 8 completes, move on to the next PR

If checking out a PR fails (e.g., conflicting local changes), in **auto mode** skip that PR and log the failure with reason; in **manual mode** stop and report. Always restore the original branch when the run finishes (or aborts), so the user's working state is not left on a random PR branch:

```bash
ORIGINAL_BRANCH=$(git branch --show-current)
# ... process PRs ...
git checkout "$ORIGINAL_BRANCH"
```

Refuse to start the multi-PR flow if the working tree has uncommitted changes — checking out other branches would either overwrite or block on them. **auto mode** logs and exits; **manual mode** asks the user to stash or commit first.

## Step 2 — Fetch All Comment Types

A pull request carries feedback in three different APIs. Fetch all of them so nothing is missed. **Include resolved and outdated comments** — the user explicitly wants the full set considered, since a "resolved" thread may still contain unaddressed sub-points.

```bash
# 1. Inline review comments (line-anchored, threaded)
gh api repos/<owner>/<repo>/pulls/<num>/comments --paginate

# 2. Review summary bodies (Approved / Changes Requested / Commented)
gh api repos/<owner>/<repo>/pulls/<num>/reviews --paginate

# 3. Issue-style PR conversation comments
gh api repos/<owner>/<repo>/issues/<num>/comments --paginate
```

Normalize every comment into this internal structure:

```json
{
  "id": "<api id>",
  "source": "inline | review_body | issue",
  "author": "<login>",
  "author_type": "user | bot",
  "path": "<file path or null>",
  "line": "<line or null>",
  "body": "<text>",
  "created_at": "<iso>",
  "in_reply_to": "<id or null>",
  "resolved": true | false,
  "outdated": true | false,
  "html_url": "<link>"
}
```

For inline comments grouped into threads, treat the **whole thread** as one unit so you can read replies before deciding what to do.

## Step 3 — Filter Already-Processed Comments

To make this skill safe to run repeatedly (especially in scheduled mode), avoid re-processing comments you've already handled. Determine "already processed" by:

1. **Git log search**: for each comment, check whether a recent commit message references its `html_url` or `id`. The `commit` skill writes ticket IDs into messages, and this skill appends the comment URL (see Step 6), so previous runs are discoverable via:
   ```bash
   git log --since="60 days ago" --grep="<comment id or short url>" --oneline
   ```
2. **Skip when matched**: if a commit referencing the comment exists on the current branch, skip the comment without further evaluation.

This filtering happens **before** classification so already-handled comments don't even get evaluated.

## Step 4 — Classify Each Remaining Comment

For each comment (or thread), decide whether it requires a code change. Classify into one of:

| Class | Definition | Action |
|-------|-----------|--------|
| `actionable` | Concrete request to change code, fix a bug, rename, refactor, add tests, etc. | Fix in Step 5 |
| `question` | Asks for clarification or "why did you do X?" | **Skip + log** |
| `discussion` | Design discussion with no specific change request | **Skip + log** |
| `lgtm` | Approval, "looks good", "nice work", emoji-only | **Skip + log** |
| `bot` | Posted by a bot account (`author_type == "bot"`, or known bot login) | **Skip + log** |
| `already_done` | The comment is satisfied by current code state (verify by reading the file) | **Skip + log** |
| `unclear` | Cannot tell what is being asked | **auto**: skip + log. **manual**: ask the user. |

Per project decision, **all non-actionable classes are skipped silently** — do not auto-reply to questions or discussions. Just record them in the run log so the user can review later.

## Step 5 — Investigate and Fix Actionable Comments

For each `actionable` comment, you need to (a) understand what is being asked, (b) confirm the requested change is correct, and (c) apply it. Don't just make the change blindly — a reviewer might suggest something that conflicts with another part of the codebase or another comment.

### Investigation

For each actionable comment:

1. **Read the referenced code** at `path:line` plus surrounding context.
2. **Check for conflicting comments** — if two comments touch the same lines and propose different things, decide based on the more recent one or the one with more context. In unclear cases, **manual mode** asks the user; **auto mode** picks the safer/more conservative option and logs the conflict.
3. **Trace the impact** — does the requested change have ripple effects elsewhere? If so, those need to be addressed in the same fix.

For complex cases (multiple files, design changes), spawn an Explore agent rather than tracing inline. This protects the main context.

### Apply the Fix

Make the actual code change. Keep changes minimal and focused on what the comment asked for — don't gold-plate or refactor adjacent code. After each fix:

- Run the project's lint/build/test command if one exists and is fast (under ~30s). If it's slow, defer to the project's CI.
- If the fix breaks tests, **fix the implementation** rather than skipping or modifying tests to pass.

### Fix Failure Handling

If a fix cannot be applied (the code has moved, the request requires architectural change, the fix breaks unrelated tests after a reasonable retry):

- **auto mode**: skip the comment, log the failure with reason, and continue to the next comment. Do not abort the whole run.
- **manual mode**: stop and report the situation to the user before proceeding.

## Step 6 — Commit via the `commit` Skill

After all fixes are applied (or after each logical group, see below), invoke the `commit` skill to create the commit(s).

### When to commit

Group fixes into logical commits using the `commit` skill's natural splitting behavior — that skill already analyzes staged changes and groups them by meaning. So:

1. Stage all the fixes from Step 5: `git add -A` (only the files this skill modified — track them as you go to avoid sweeping in unrelated user work).
2. Invoke the `commit` skill via the Skill tool: `Skill(skill: "commit")`.

### Commit message annotation

After the `commit` skill creates each commit, append a trailer that links the comment(s) addressed by the commit. This is what makes Step 3's "already processed" filter work on the next run.

Use `git commit --amend` immediately after each commit to add a trailer block:

```
Addresses-PR-Comment: <html_url 1>
Addresses-PR-Comment: <html_url 2>
```

(Use one line per comment. The trailer name is searchable via `git log --grep`.)

### Auto vs manual ID handling

The `commit` skill already determines a ticket ID from the branch name or PR. Pass through to it as-is — no special handling is needed in this skill, because:

- In **auto mode**, if the `commit` skill cannot determine an ID, it normally asks the user. But since this skill is running autonomously, instruct the commit skill to proceed without an ID rather than blocking. Pass the directive through the Skill tool args: `Skill(skill: "commit", args: "--auto")` if the commit skill supports it; otherwise pre-resolve the ID before invoking and provide it as part of the args.
- In **manual mode**, let `commit` behave normally — it will only ask the user as a last resort, which matches this skill's "only ask when truly needed" policy.

If the `commit` skill does not support `--auto`, fall back to: detect the PR number / branch ticket ID yourself before invoking commit, and let it auto-detect from the same sources.

## Step 7 — Push

After commits succeed, push to the remote tracking branch unconditionally:

```bash
git push
```

Per project decision, the skill always pushes to the **current branch** with no protection check. If `git push` fails because there is no upstream, set one explicitly:

```bash
git push -u origin <current branch>
```

If the push is rejected because the remote has new commits (someone else pushed), in **auto mode** abort the run and log the conflict — do **not** force-push or auto-rebase. In **manual mode**, report the situation to the user and ask how to proceed.

## Step 8 — Run Summary

After everything completes, write a concise report. Even in auto mode, output the report so it lands in the scheduled job's logs.

When the run processed multiple PRs, emit one per-PR section followed by a top-level totals block. Single-PR runs can omit the totals block.

```markdown
# PR Comment Fix Run

**Scope**: single | repo | branch | filtered repo (authors=<list>, drafts=<bool>)
**Mode**: auto | manual
**PRs processed**: N (M skipped due to checkout failures)

## PR #123 — <title>
**Branch**: <head ref>

### Fixed (N)
| Comment | File | Commit |
|---------|------|--------|
| <short url> | path:line | <commit sha> |

### Skipped (M)
| Comment | Class | Reason |
|---------|-------|--------|
| <short url> | lgtm | approval, no action needed |
| <short url> | already_done | code already matches request |

### Failed (K)
| Comment | Reason |
|---------|--------|
| <short url> | tests broke after fix, retried 2x |

### Push
- Pushed N commits to origin/<branch>

<!-- repeat per PR for multi-PR runs -->
```

In auto mode, if **no** comments needed fixing across the entire scope, still emit a one-line heartbeat summary so the scheduled job has signal: `pr-comment-fix: scope=<repo|branch|...>, N PRs, 0 actionable comments, nothing to do.`

## Tips

- **Idempotency is critical** for the auto mode. The Step 3 filter is what makes this safe to run on a cron — without it, the same comment could be "fixed" repeatedly. Test the filter against a real run before relying on the cron.
- When a comment thread has multiple replies, the **latest** comment usually represents the current ask. Earlier messages may be stale.
- A reviewer suggesting "consider X" is softer than "this must be Y". Treat suggestions as `actionable` only if they describe a concrete change; otherwise log as `discussion`.
- If you find yourself wanting to change many files for one comment, stop and reconsider — the comment probably points at a deeper issue that deserves a separate PR rather than a sprawling fix on this branch.
