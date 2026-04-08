---
name: qa-inspect
description: >
  ユーザーの質問に「回答のみ」を返す読み取り専用Q&Aスキル。
  PR/ブランチ/コミット履歴、仕様・ドキュメントとの整合性、実装の妥当性や設計判断について、
  「〜はどうなってる？」「〜で合ってる？」「〜の理由は？」「このPRの変更意図は？」
  「このブランチは何のため？」「この実装で問題ない？」「仕様と矛盾してない？」
  等の質問に対して、コード・git履歴・ドキュメントを調査して回答する。
  ユーザーから明示的に指示されない限り、ファイル編集・コミット・PR操作など一切の変更を行わない。
  セッション終了時または明示要求時に、Q&Aテーブルと詳細レポートを単一のMarkdownファイルに出力する。
argument-hint: <first question | "report" | "end">
---

# qa-inspect: Read-Only Q&A Inspector

Answer the user's questions about PRs, branches, commits, work-in-progress changes, and implementation decisions — **without modifying anything**. This skill is a **mode**, not a one-shot: once entered, every subsequent user message is treated as another question in the same Q&A session until the user ends it, and a single Markdown report is compiled at the end.

## Mode Lifecycle

This skill works as a stateful mode with three phases: **enter → ask/answer loop → exit + report**.

### Entering the mode

The user enters Q&A mode by any of:

- Invoking `/qa-inspect` (with or without an initial question as argument)
- Saying things like "Q&Aモードに入って", "質問モードで", "let's do Q&A", "I want to ask you a bunch of things about this repo"
- An initial question that clearly implies a session (e.g. "このブランチについて色々聞きたい")

On entering, immediately:

1. Acknowledge mode entry in one short line (e.g. "Q&A mode started. Ask away — I'll answer only, no edits. Say 'report' or 'end' when done.")
2. Initialize an empty session log (see **Session Log** below).
3. If the invocation already included a first question, proceed to answer it as Q1.
4. Otherwise, wait for the first question.

### The ask/answer loop

Once in mode, **every user message is treated as the next question** (Q2, Q3, ...) unless it is clearly one of:

- A meta-command: `report`, `end`, `exit`, `done`, `終わり`, `レポート出して`, etc. → go to exit phase.
- A correction/clarification of the **previous** question (e.g. "no I meant the other file"). → treat as refining Qn, not as a new Qn+1.
- An explicit instruction to leave Q&A mode and do something else (e.g. "OK now actually fix that bug"). → exit the mode first, then hand off.

For each new question, follow the **How to Answer** procedure below, then append the exchange to the session log and wait for the next question. Do **not** re-announce the mode on every turn — one acknowledgment at entry is enough. Stay in mode silently and just keep answering.

If you are uncertain whether a given user message is a new question or a mode-exit signal, ask once (e.g. "Is that a new question, or are we wrapping up?") rather than guessing.

### Exiting the mode

Exit when the user sends any of:

- An explicit meta-command: `report`, `end`, `exit`, `done`, `終わり`, `レポート出して`, `まとめて`, `/qa-inspect report`, etc.
- A clear session-wrap signal: "ありがとう、以上で終わり", "that's all for now", "wrap this up", etc.
- An instruction that requires leaving Q&A mode to act (e.g. "OK fix it", "go ahead and commit that"). In this case exit *first*, write the report, *then* hand off.

On exit:

1. Write the report to `qa-report.md` per the **Report Output** section.
2. Tell the user the file path and the count of entries saved.
3. Clear the in-memory session log.
4. Return to normal (non-Q&A) behavior.

If the user sent only one or two questions and then immediately exits, still write the report — even a 2-entry report is useful as a record.

## Core Principle: Answer Only

This skill is **strictly read-only**. The user asks, you investigate, you answer. That's it.

- Do **not** edit files, stage changes, create commits, push branches, open PRs, or run any command that mutates state.
- Do **not** "helpfully" fix issues you find while investigating. Report them as part of the answer instead.
- If the user explicitly asks you to fix something after seeing an answer (e.g. "OK, fix it"), that is a separate request outside this skill's scope — hand off to normal editing behavior at that point.

This mirrors the user's global rule that investigation/question prompts must return findings only, not silent fixes. The reason is trust: the user wants to build a mental model of the codebase first, then decide what to change.

## Scope of Questions

This skill handles questions in three families. Any of them may appear in a single session.

### 1. Git state — PRs, branches, commits, working tree

Examples:
- "What's on this branch that isn't on main yet?"
- "Why does this commit touch `auth.ts`?"
- "What PR introduced this function?"
- "What files do I have staged right now?"
- "Is this branch behind main?"

Tools to reach for: `git log`, `git diff`, `git status`, `git show`, `git blame`, `gh pr view`, `gh pr diff`, `gh pr list`.

### 2. Spec / documentation consistency

Examples:
- "Does this implementation match what the README says?"
- "The design doc says X — is the code actually doing X?"
- "Is this API behavior documented anywhere?"

Read the relevant docs (`README.md`, `docs/`, design files, comments) **and** the code, then compare. If they disagree, say so plainly and cite both sides (file:line on each).

### 3. Implementation validity / design judgment

Examples:
- "Does this implementation have any problems?"
- "Is this the right place for this logic?"
- "Why would someone write it this way?"
- "Is this safe under concurrent access?"

These are judgment questions. Answer with reasoning, not just facts: what the code does, what could go wrong, what alternatives exist, and — importantly — what you are *not* sure about. If you'd need to run the code or add instrumentation to be certain, say so instead of guessing.

## How to Answer

For every question the user asks:

1. **Understand the question.** If it's ambiguous (e.g. "is this OK?" with no referent), ask one short clarifying question before investigating. Don't waste a large investigation on the wrong target.
2. **Investigate with read-only tools.** Read files, run `git`/`gh` commands that don't mutate, grep the codebase. Follow references until you actually have an answer — don't stop at the first plausible guess.
3. **Answer directly.** Lead with the answer, then the evidence. Use `file_path:line_number` citations so the user can verify. For git/PR answers, quote the relevant commit hash or PR number.
4. **Be honest about uncertainty.** If the evidence is incomplete or contradictory, say which part you're sure of and which part you're inferring.
5. **Record the Q&A.** Append the question, your answer, and the supporting evidence to the in-session log (see below). This is what the final report is built from.

### Answer structure

A good answer looks like this:

```
**Answer:** <one or two sentences, the direct answer>

**Evidence:**
- `src/auth.ts:42-58` — the token is validated here before the DB lookup
- `docs/auth.md:15` — the documented flow matches

**Uncertainty:** <what you couldn't verify, if anything>
```

Short questions deserve short answers. Don't pad. The structure above is a ceiling, not a floor — a one-line question about "what branch am I on" gets a one-line answer.

## Session Log

Keep an internal running list of every Q&A exchange in this session. For each entry, track:

- `id` — sequential number (Q1, Q2, ...)
- `question` — the user's question, verbatim or lightly cleaned up
- `answer_summary` — one-sentence distilled answer for the table
- `answer_detail` — the full answer you gave (including evidence and uncertainty)
- `category` — one of `git`, `docs`, `implementation`, `other`
- `sources` — list of files/commits/PRs consulted

You don't need to write this to disk on every turn. Hold it in working memory until report time.

## Report Output

### When to emit the report

Emit the report in either of these situations:

1. **Explicit request** — the user says "report", "レポート出して", "まとめて", "save the Q&A", `/qa-inspect report`, or similar.
2. **Session-end signal** — the user says things like "ありがとう、以上で終わり", "that's all", "done for now", "wrap this up", "終わり", or otherwise clearly signals the Q&A session is ending.

When in doubt about case 2, ask: "Session seems to be wrapping up — should I save the Q&A report to `qa-report.md`?" One short confirmation is better than either missing the signal or writing a file the user didn't want.

### Report location and format

Write a **single file** named `qa-report.md` in the current working directory (or the path the user specifies). If a `qa-report.md` already exists, append a new dated section rather than overwriting — the user may have prior sessions to preserve.

Use this exact template:

```markdown
# Q&A Report — <YYYY-MM-DD HH:MM>

**Repository:** <repo name or path>
**Branch:** <current branch>
**Session questions:** <N>

## Summary Table

| # | Category | Question | Answer (summary) |
|---|----------|----------|------------------|
| Q1 | git | What's on this branch vs main? | 3 commits adding auth middleware |
| Q2 | implementation | Is the token validation safe? | Yes for single-node; race risk under HA |
| ... | | | |

## Details

### Q1 — What's on this branch vs main?

**Category:** git
**Sources:** `git log main..HEAD`, commits `81d2983`, `4143756`, `f1ad9ee`

**Answer:** Three commits adding auth middleware, all by Shota Iuchi on 2026-04-07.

**Evidence:**
- `81d2983` feat: add JWT middleware — `src/auth/jwt.ts:1-84`
- `4143756` wire middleware into router — `src/server.ts:22`
- `f1ad9ee` add tests — `tests/auth/jwt.test.ts`

**Uncertainty:** None — all commits are clean and pushed.

---

### Q2 — ...
```

Rules for the report:

- **Summary table first.** The table is the navigation — it must cover every question in order.
- **Details below.** Each question gets its own subsection with the full answer verbatim from the session. Don't rewrite history; preserve what was actually said.
- **Cite sources.** Every details entry lists the files, commits, or PRs consulted.
- **Do not invent answers for questions you didn't actually investigate.** If a question was deferred or skipped, mark it as such.

### After writing the report

Tell the user the path and a one-line summary (e.g. "Saved 7 Q&A entries to `qa-report.md`"). Do not open it, do not commit it, do not push it — that's mutation, and this skill does not mutate.

## What This Skill Is Not

- **Not a code fixer.** If the answer reveals a bug, report the bug. Wait for the user to say "fix it" before doing anything else.
- **Not a PR creator.** It can read PR content (`gh pr view`, `gh pr diff`) but never runs `gh pr create`, `gh pr merge`, `gh pr comment`, etc.
- **Not a commit author.** It can read `git log` / `git show` / `git blame` but never runs `git commit`, `git push`, `git rebase`, `git reset`, or anything else that changes refs or the working tree.
- **Not a silent investigator.** Every investigation results in a visible answer to the user, not just internal notes.

If a question genuinely cannot be answered without mutating state (rare, but possible — e.g. "what would `git rebase` do?"), explain what you'd need to do and ask the user to either run it themselves or grant explicit permission for a dry-run.
