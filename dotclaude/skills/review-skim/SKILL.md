---
name: review-skim
description: >
  AI生成コードのレビュー時に「全体の流れだけを把握するため」のスキミング用ビューを生成するスキル。
  指定ファイル群・PR差分・ブランチ差分を入力に、クラス/関数のシグネチャ、既存コメント、
  上位レベルの制御フロー、副作用呼び出しだけを残した圧縮ビューをMarkdownで出力する。
  他の関数を呼ばない「末端関数」の中身は自然言語の1行要約に置き換え、
  要約である旨を明示する。コメントが欠落している箇所はレビュー指摘候補として記録する。
  「レビュー用に流れだけ見たい」「全体像を掴みたい」「末端の実装は読み飛ばしたい」
  「このPRのロジックだけざっと把握したい」等の依頼で使用する。
argument-hint: <files... | "pr <number>" | "branch <base>..<head>">
---

# review-skim: Skimming View for Code Review

Generate a **skim view** of code — a compressed representation whose only purpose is to let a human reviewer understand the **overall flow** of AI-generated code without reading every line. Syntax-level correctness is assumed (reviewers don't read leaf implementations to catch typos); what matters is *what the code is doing and in what order*.

The output is a single Markdown file. The reviewer uses it to decide where to look deeper — it is **not** a replacement for reading the actual code before approving, only a navigation aid.

## Core principle: strip detail, preserve flow

The reviewer's mental model is built from three things:

1. **Structure** — which files, classes, and functions exist and how they relate.
2. **Intent** — what each piece is *trying* to do, as stated in comments or inferable from names.
3. **Flow** — the order of operations at the top level (control flow, calls, side effects).

Everything that does not contribute to these three is noise for skimming purposes. Loop bodies that just transform data, argument validation, getter/setter boilerplate, syntactic ceremony — all of it gets collapsed. What remains should read like pseudocode.

## Input modes

The user specifies *what* to skim. Support three modes:

### 1. File mode
`review-skim path/to/a.ts path/to/b.py`
Skim the given files in full.

### 2. PR mode
`review-skim pr 123`
Fetch the PR diff via `gh pr diff 123` (and `gh pr view 123` for metadata). Skim only the **changed regions** of changed files. Include a few lines of surrounding context per hunk so the reviewer can situate each change, but do not expand to the whole file unless the diff itself is whole-file.

### 3. Branch-diff mode
`review-skim branch main..HEAD` (or any `<base>..<head>` spec)
Use `git diff <base>..<head>` to find changed files and regions. Same rule as PR mode: skim only the changed regions plus small context.

If the user's request is ambiguous (e.g. "skim the recent changes"), ask which mode they mean before doing work — the three modes read very different amounts of code.

## What to keep vs. what to collapse

### Keep verbatim
- **File paths and headings** — one section per file.
- **Top-level declarations** — classes, functions, methods, exported constants. Preserve the signature exactly (name, parameters, return type if present).
- **Existing comments** that describe *what* or *why*, especially docstrings and block comments above declarations. These are the reviewer's primary source of intent.
- **Top-level control flow inside non-leaf functions** — `if` / `else` / `for` / `while` / `try` / `switch` branches, but only the branching structure, not the full body of each branch unless the body itself contains further flow.
- **Calls to other first-party functions.** These are the edges of the flow graph the reviewer is trying to see — where the code hands off to another piece the author wrote. Library/framework calls do not need to be preserved as call sites; they are better expressed as side-effect labels (see below) when they matter, or omitted when they are pure data shaping.
- **Side effects** — network requests, DB queries, file I/O, subprocess/shell calls, env var reads, global state mutation. Keep these so the reviewer can spot where the code touches the outside world. They may be abstracted to natural language if that is clearer (see below).

### Collapse or summarize
- **Leaf function bodies.** A function is a *leaf* if it does not call any other **first-party** function — that is, any function defined elsewhere in the same repository. Library/framework calls and language built-ins do **not** disqualify a function from being a leaf; a function that only calls `fetch`, `JSON.parse`, `fs.readFile`, etc. is still a leaf. The reason is that the reviewer is trying to see the shape of the *author's* code, and library calls are better represented as natural-language side-effect labels inside the leaf's summary than as expanded call sites. For leaves, replace the body with a **one-line natural-language summary** of what it does, clearly marked as a summary (see "Summary marking" below). If the leaf performs notable side effects, mention them in the summary (e.g. `// [summary] HTTP GET to /users/:id, returns parsed JSON or null on 404.`).
- **Pure data plumbing** — assignments, destructuring, field copying, format string building — inside non-leaf functions. Collapse consecutive pure-plumbing lines into a single `// ... (data shaping)` placeholder.
- **Argument validation / guard clauses** — collapse into `// ... (argument checks)` unless the validation itself is non-trivial (e.g. cross-field invariants worth reviewing).
- **Imports** — list them only if they reveal something surprising (new external dependency, unusual module). Otherwise omit.

### Abstraction of side effects (optional)
Side effects may be written either as the literal call or as a natural-language label, whichever communicates intent better:

- Literal: `await db.users.findOne({ id })`
- Abstracted: `// [side effect] DB read: fetch user by id`

Use the abstracted form when the literal call is long, noisy, or buried in builder chains. Use the literal form when the exact API or arguments are themselves review-worthy. When in doubt, prefer the literal form — it gives the reviewer a precise anchor to jump to.

## Summary marking

When a leaf function body is replaced by a summary, the summary is **your inference**, not ground truth. The reviewer must be able to tell at a glance which lines are real and which are summarized, because a wrong summary can mislead a review.

Mark every summarized body with a visible tag. Use exactly this format:

```
function fetchUserProfile(id) {
  // [summary] Parses the id, looks up cached profile, returns it or null.
}
```

The tag `[summary]` is mandatory. Do not paraphrase it, do not drop it, do not rely on context to make it obvious. It is the reviewer's signal that *this block was not read, it was guessed at from the function name and surrounding calls*.

If you cannot confidently summarize a leaf (e.g. the function name is opaque and there are no comments), write `// [summary] (unclear — read directly)` rather than inventing intent.

## Missing-comment findings

A secondary goal of this skill is to surface comment gaps — places where the reviewer will have to read the code because the author left no explanation. **Every declaration (function, method, class, exported constant) that lacks an explanatory comment is a review finding**, and must be collected into a "Review findings" section at the bottom of the output.

A comment counts as "explanatory" if it describes *what* the code does or *why*, at a level a reviewer could act on. A restating-the-signature comment (`// sets the name`) does not count.

The findings section is additive: it does not replace the per-file skim, it supplements it. The reviewer uses the per-file skim to understand the flow and the findings section to decide what to ask the author about.

## Output format

Write one Markdown file (default: `review-skim.md` in the current working directory, or a path the user specifies).

Template:

````markdown
# Review Skim — <target description>

**Mode:** <file | pr | branch>
**Target:** <file list | PR #N | base..head>
**Generated:** <YYYY-MM-DD HH:MM>

## How to read this document

This is a **skimming view**, not the real code. Lines marked `[summary]` are inferences about leaf functions whose bodies were not included — treat them as a hypothesis to verify, not as fact. Lines marked `[side effect]` are natural-language stand-ins for real calls.

Use the "Review findings" section at the end to see which declarations lack explanatory comments.

---

## <file path 1>

> <existing file-level comment or docstring, if any>

```<language>
class Foo:
    """<existing class docstring verbatim>"""

    def handle_request(self, req):
        # <existing comment verbatim>
        if req.is_authenticated:
            user = self.load_user(req.user_id)
            // [side effect] DB read: fetch user profile
            return self.render(user)
        else:
            return self.redirect_to_login()

    def load_user(self, user_id):
        # [summary] Looks up a user row by id and maps it to a domain object.
```

## <file path 2>

...

---

## Review findings

Declarations lacking explanatory comments (reviewer should ask the author or read directly):

- `src/foo.py:42` — `Foo.handle_request` — no docstring; purpose inferred from body
- `src/foo.py:58` — `Foo.load_user` — leaf function, no comment, summary is a guess
- `src/bar.ts:10` — `parseConfig` — no comment
````

Rules for the output:

- **One section per file**, in the order the user specified them (or the order `git diff` returned them).
- **Use fenced code blocks with language tags** so syntax highlighting works when the reviewer opens the file.
- **Preserve original indentation** inside code blocks — the reviewer is scanning visually, and consistent indentation is what makes control flow readable.
- **Do not invent code that isn't in the source.** The only content you add is `[summary]` lines, `[side effect]` labels, and `// ... (collapsed)` placeholders. Everything else must be copied from the real file.
- **Do not reorder** declarations within a file. Keep them in source order.
- **PR/branch mode**: include a short header per file indicating what changed (`+42 / -10 lines`, or the hunk ranges) so the reviewer knows the scope of each file's change.

## Procedure

1. **Parse the invocation** to determine mode (file / pr / branch) and targets. If ambiguous, ask once.
2. **Gather the source to skim:**
   - File mode: read each file in full.
   - PR mode: `gh pr view <n>` for metadata, `gh pr diff <n>` to find changed files and hunks, then read the changed files and focus on the hunk regions (with a few lines of context).
   - Branch mode: `git diff <base>..<head> --name-only` and `git diff <base>..<head>` for the same purpose.
3. **For each file**, walk the declarations in source order. For each declaration:
   - Copy the signature and any explanatory comment verbatim.
   - Decide whether it's a leaf (no calls to other **first-party** functions from the same repo; library calls and built-ins do not count).
   - If leaf: write a one-line `[summary]` describing what it does, based on name + any comments + what little body you read. If you can't be sure, say so.
   - If non-leaf: reproduce the top-level control flow and call sites, collapsing pure plumbing. Nested non-leaf calls inside branches should be kept as calls, not expanded.
   - If the declaration has no explanatory comment, record it for the findings section.
4. **Write the Markdown file** using the template above.
5. **Tell the user** the output path, how many files were skimmed, and how many findings were recorded. Do not open, commit, or push the file.

## What this skill is not

- **Not a substitute for reading the code.** The output explicitly says so at the top. If the reviewer approves based only on the skim, that's on the reviewer.
- **Not a linter.** It does not evaluate correctness, style, or security. The `[summary]` lines are descriptive, not judgmental. The only "finding" it emits is missing comments.
- **Not a rewriter.** It never edits the source files. It only reads them and writes one Markdown output.
- **Not language-specific.** Treat the source at a structural level — declarations, comments, control flow, calls. If the language uses unusual syntax, do your best to map it onto those concepts rather than bailing out.

## Why this exists

Reviewing AI-generated code is different from reviewing human-written code. The reviewer's job has shifted: syntax is almost always fine, variable names are reasonable, and individual leaf functions usually do what they claim. What breaks is the **overall logic** — wrong sequencing, missing cases, right building blocks wired together wrong. That kind of bug is invisible when you're three levels deep inside a helper. It only becomes visible when you step back and look at the shape of the whole thing at once.

The skim view exists to give the reviewer that step-back view on demand, so they can form a hypothesis about the overall flow first, and only then dive into the specific functions that look suspicious. The `[summary]` and missing-comment machinery exists to make the skim honest: the reviewer always knows which parts they've actually looked at and which parts they're taking on faith.
