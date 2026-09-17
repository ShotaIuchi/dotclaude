---
name: review-design
description: >
  PR・ブランチ差分・作業中の変更に加え、差分の無い既存コード（ファイルやディレクトリの指定）も入力にできる、コードの設計を図で見せるスキル。要件/基本設計/詳細設計を4枚の
  Mermaid 図（業務フロー・コンポーネント図・クラス図・呼び出しシーケンス図）にまとめた「ペライチ」の設計資料を生成する。コードレビュー前や既存コードの把握時に、文章を読まずに
  設計を視覚的に理解できるようにすることが目的。クラス構造と関数呼び出しの流れを必ず図にし、変更がある場合は変更箇所をマーカーと色で強調する。文章は図ごとに2行程度のキャプションに留
  める。「このPRの設計を図にして」「変更の全体像を図で見たい」「レビュー用の設計資料を作って」「クラス図がほしい」「関数の呼び出しの流れを図にして」「どこから呼ばれてどこへ行くのか
  知りたい」「何に依存しているのか」「どこがどう繋がってるのか図解して」「文章じゃなくて図で説明して」「実装中の設計を可視化して」「この辺のコードの構造を把握したい」等の依頼で使用す
  る。要約テキストではなく図が欲しい場合は必ずこのスキルを使う。
argument-hint: <pr NUMBER | branch BASE..HEAD | working | FILES...>
---

# review-design: a one-page visual design brief

Produce **one page** with four diagrams and a short table of where to look. It should print on a single A4 page and be readable without scrolling.

| Section | Diagram | The question it answers |
|---|---|---|
| 1. 要件 | `flowchart` — actor → new capability → outcome | 誰の何が変わるのか |
| 2. 基本設計 | `flowchart` — component view | どこに置かれ、何に依存するのか |
| 3. 詳細設計 — 構造 | `classDiagram` | 型・クラスとその関係はどうなるのか |
| 4. 詳細設計 — 振る舞い | `sequenceDiagram` | どの関数がどの順で呼ばれるのか |
| 5. レビューで見るところ | table (3–5 rows) | どこを疑って読むべきか |

The reader already has the diff. What they lack is its *shape*. This page supplies the shape, and stops there.

## Why this shape

Someone is about to review a PR. Four questions stand between them and a useful review: what is this for / where does it sit / what runs and in what order / where should I look hard. Prose answers these slowly; a picture answers them at a glance.

Sections 3 and 4 are deliberately a pair. A class diagram shows the *structure* — what exists and how it is related — but not what actually happens; a sequence diagram shows the *calls* but leaves the shape of the types implicit. Reviewers need both, and neither substitutes for the other, so both get a slot.

The page limit is not decoration. A reviewer who has to scroll is reading a document again, which is the thing they were trying to avoid. And being allowed one diagram per section is what forces you to draw the one that matters instead of everything you noticed.

This is a map, not a substitute for the code. Say so on the page, and never write it so that someone could approve a PR from the diagrams alone.

## Principles

**Make the delta glow.** An accurate picture of the whole system is close to worthless here — the reviewer already knows the system. What they don't know is what just changed. Every diagram marks new / modified / removed elements and carries untouched ones only in the amount needed to make the change legible. If the reviewer has to hunt for the 🆕, redraw with less context.

**Name real functions.** Sections 3 and 4 are worth the space only if they carry actual identifiers — `create_order(user_id, items)`, not `注文を作る`. Those names are how the reviewer jumps from the picture into the code. Keep them verbatim, including case and underscores.

**Merge rather than add.** A fifth diagram is almost never the answer. States become `Note over` annotations on the sequence diagram, a schema change becomes a labelled datastore node in the component view, an old code path stays in the same diagram as a 🗑 dashed branch. Folding keeps the page; adding costs it.

**A diagram nobody can read is worse than none.** Around 15 nodes (or 7 participants) is the ceiling. Past it, raise the abstraction level so several boxes collapse into one.

**Claim only what you checked.** Section 5 is where this page can do real damage — a confident wrong claim sends a reviewer down the wrong path, and they will trust it because it looks precise. State plainly what you verified in the code; mark the rest `未確認:` and say what would settle it. If running something would settle it cheaply (a test, a one-line script), run it.

Absence claims deserve their own paragraph because they are the ones that keep going wrong: "テストが無い", "マイグレーションが無い", "呼び出し元が無い". Nothing in a diff tells you something *doesn't* exist — you only learn that by searching, and a search that came up empty is not the same as a search you didn't run. Before writing one, grep the repository for the thing (the test file, the fixture name, the parametrized case, the migration directory) and record the term you searched in the row's mark: `✓探索(alembic)`. If you can't search it, the row gets `⚠未確認` instead.

**Write in the user's language.** Captions and headings follow the language the user is speaking; identifiers stay verbatim.

## Workflow

### Step 1 — Resolve the target

| Mode | Invocation | What to read |
|---|---|---|
| PR | `pr 123` | `gh pr view 123 --json title,body,url,headRefName,baseRefName` and `gh pr diff 123` |
| Branch | `branch main..HEAD` | `git diff --stat <spec>`, `git diff <spec>`, `git log --format='%s%n%b' <spec>` |
| Working | `working` | `git status --porcelain`, `git diff`, `git diff --cached`, plus untracked file contents |
| Files | `src/order/*.ts ...` | the given files in full |

With no argument, pick rather than ask — the user came here to avoid effort. Resolve in this order: uncommitted changes exist → `working`; otherwise the branch is ahead of its base → `branch`; otherwise an open PR exists → `pr`. State the mode on the page so a wrong guess is obvious and cheap to correct. Only ask when none of these apply.

**Files mode has no delta**, so markers don't apply. Draw the structure as it is: what the code is for, how it is arranged, what types exist, how a typical call runs through it.

### Step 2 — Gather stated intent

Read in this order: PR title and body → linked issue (`#\d+` in the body, `gh issue view N --json title,body`, at most two) → commit subjects and bodies.

Human-written intent beats anything you infer — commit bodies in particular often carry the business reason ("finance has been reconciling by hand"), which is exactly what section 1 needs and what you cannot get from the diff. When no stated intent exists, infer from the code and mark it `[推測]` on the 出典 line. Don't go hunting through `docs/`; it is slow and usually stale.

### Step 3 — Read the change

Group the diff by *meaning*, not by file: "注文作成APIの追加" is a unit; `OrderController.ts` is not.

Skip noise: lock files, `dist/` `build/` `vendor/`, generated code, snapshots, fixtures, images, formatting churn. For a very large diff, use `--stat` first and read the substantive files fully rather than skimming everything.

You need two things the diff doesn't hand you directly, so look for them on purpose:

- **the type picture** — which classes/structs/interfaces exist around the change, what they hold, which methods moved or appeared. Read the class bodies, not just the changed lines; a reviewer needs the surrounding shape to judge whether the new member belongs there.
- **the call path** — follow one representative request from its entry point (handler, command, job) through to its side effects, noting the actual function names and where the branches are. This is what section 4 draws.

While reading, collect candidates for section 5:

- new external dependencies or outbound calls (network, DB, filesystem, subprocess)
- transaction and lock boundaries
- error paths, and error paths that are conspicuously missing
- concurrency, async ordering, retries, idempotency
- schema or persisted-shape changes, and whether a migration exists
- authn/authz checks, secrets, personal data
- existing callers and tests that the change breaks

### Step 4 — Draw the four

**1. 要件** — who can now do what, and what problem that solves. A small `flowchart` of actor → new capability → business outcome. Put the *business* outcome in the rightmost node; that is what the reviewer checks the code against. For a pure refactor with no user-visible effect, draw the structural promise instead ("同じロジックが 2 箇所 → 1 箇所"). If one sentence genuinely covers it, write the sentence and skip the diagram — the other three still earn the page.

**2. 基本設計** — a `flowchart` component view: where the change sits, what it depends on, which datastores and external systems it touches. This is the diagram that orients the other two, so keep it at module/service granularity and let sections 3–4 carry the detail.

**3. 詳細設計 — 構造** — a `classDiagram` of the types the change touches, with their relationships and the members that matter. Include enough unchanged members to make the class recognizable, and mark what moved. When the change spans a hierarchy (something pulled up to a parent, an interface extracted), that hierarchy *is* the story — draw it and mark where each member now lives.

For code without classes (procedural modules, hooks, scripts, SQL), draw the same idea in a `flowchart`: modules as boxes, their exported functions as the members, edges for imports. The point of the slot is "what exists and how it is related", not the `classDiagram` keyword specifically.

**4. 詳細設計 — 振る舞い** — a `sequenceDiagram` of one representative call path, with real function names on the messages. `alt` for the failure branches — the error path is usually the interesting part of a review. Fold in what would otherwise need its own diagram: new states as `Note over`, transaction boundaries as a `Note over A,B`, retries as `loop`.

Choose the path that carries the most risk, not the simplest one. If two paths both matter (create and cancel, say), draw the riskier and give the other one line in section 5.

### Step 5 — Verify the diagrams render

A Mermaid block with a syntax error renders as a red error box on GitHub, and the page is then worth less than nothing:

```bash
python3 scripts/check_mermaid.py <output.md>
```

It reports unbalanced `subgraph`/`end`, invalid node IDs, unquoted characters that break labels, `class` references to undefined `classDef`s, node counts over the readable limit, and `classDef`s missing an explicit `color:` (which makes labels vanish in dark mode). Fix everything it reports.

For a real render pass, add `--render`: it uses `mmdc` if installed, otherwise `npx -y @mermaid-js/mermaid-cli`. The npx route downloads a browser the first time (slow, a few minutes) and is fast afterwards — worth it when you have used an unusual construct and want proof it draws.

### Step 6 — Hand over

Write one Markdown file, default `review-design-<slug>.md` in the current directory (`pr123`, `branch-main-HEAD`, `working`, `files`), or wherever the user asked. Then give the path in one line — don't re-explain the change in chat, since the page exists so nobody has to read an explanation.

## Marking the delta

Emoji markers are the primary signal, colors are backup: emoji survive every renderer and both themes, `classDef` fills do not.

- 🆕 new / ✏️ modified / 🗑 removed / no marker = existing context

Where each kind of diagram takes the marker (all four forms below are verified to render on Mermaid 11):

| Diagram | How to mark |
|---|---|
| `flowchart` | in the label: `SVC["🆕 OrderService"]`, plus `classDef` colors |
| `sequenceDiagram` | `participant PAY as 🆕 PaymentClient`, and on messages: `API->>SVC: ✏️ create_order(...)` |
| `classDiagram` | class label syntax `class Parameter["✏️ Parameter"]`, and members **suffixed**: `+help str 🆕` |
| `stateDiagram-v2` | in the state label, plus `classDef` colors |

In `classDiagram`, a marker at the *start* of a member line breaks the `+name : type` formatting — always put it at the end.

For `flowchart` and `stateDiagram`, add color. Always specify `color:` alongside `fill:`, or GitHub's dark theme leaves unreadable labels:

```
classDef added fill:#dafbe1,stroke:#2da44e,stroke-width:2px,color:#1a1a1a
classDef changed fill:#fff5d6,stroke:#bf8700,stroke-width:2px,color:#1a1a1a
classDef removed fill:#ffe2e0,stroke:#cf222e,stroke-width:2px,color:#1a1a1a
classDef context fill:#f0f2f4,stroke:#9aa4ae,color:#3a3a3a
class API,SVC added
```

The legend goes in the header line, once.

## Mermaid rules that matter

These are the failures that actually happen; `references/mermaid-patterns.md` has the rest and a template per diagram type.

- **Node IDs**: ASCII letters, digits, `_`, starting with a letter. Japanese and symbols go in the *label*.
- **Quote every label containing `(` `)` `,` `:` `[` `]` `{` `}` `/`** — `API["POST /orders (v2)"]`. Quoting is never wrong, so quote by default.
- **Line breaks in labels**: `<br/>`, not `\n`.
- **`end` is always lowercase**, and every `subgraph` / `alt` / `opt` / `loop` / `par` / `rect` needs one.
- **Edge labels**: `A -->|"作成 (非同期)"| B` — quote these too.
- **classDiagram generics** use `~`: `List~Order~`, never `List<Order>`.

## Output template

````markdown
# 設計ビュー — <対象>

<PR #123 | branch main..HEAD | 作業中の変更 | 指定ファイル> / <YYYY-MM-DD HH:MM> / 凡例: 🆕 新規 ✏️ 変更 🗑 削除 ／ 確認: ✓実行 ✓確認 ✓探索 ⚠未確認 / この資料は地図であり、コードの代わりではありません

**一行で言うと:** <この変更が何をするのか、1文>

## 1. 要件

```mermaid
<actor → 新しくできること → 業務上の成果>
```

*出典: <PR本文 | Issue #45 | コミットメッセージ | [推測]>*

## 2. 基本設計

```mermaid
<component view>
```

**読みどころ:** <図から読み取れないことだけ、2行以内>

## 3. 詳細設計 — 構造

```mermaid
<classDiagram>
```

**読みどころ:** <2行以内>

## 4. 詳細設計 — 振る舞い

```mermaid
<sequenceDiagram、メッセージは実際の関数名>
```

**読みどころ:** <2行以内>

## 5. レビューで見るところ

| # | 場所 | 何を見るか |
|---|---|---|
| 1 | `app/order_service.py:39-58` | 与信が残るのに注文が無い状態が起きうる ✓確認 |
| 2 | `tests/test_order_service.py:24` | 引数追加に追随せず `TypeError` で全滅 ✓実行 |
| 3 | `app/payment_client.py:73` | `void()` が全例外を握り潰す ✓確認 |
| 4 | `schema.sql:12` | `payments` のマイグレーションが無い ✓探索(alembic) |
| 5 | `app/config.py:6` | 鍵未設定が 503 として見える ⚠未確認(プロバイダの応答) |
````

Keep the five sections even when one is thin — they tell the reader where to look. A section with nothing worth a diagram gets one line instead ("既存の構成に変更なし")。

Section 5 is where the page earns its keep: point at specific files and lines and say what to look for. Three to five rows, ordered by how much a mistake there would cost.

**Keep each cell to one sentence, around 60 characters, ending in a confirmation mark.** This is the rule most likely to slip, because every row feels like it deserves its evidence, its consequence and its caveat — and three sentences later the table is prose again, which is exactly what the reader came here to escape. The cell's job is to make someone open that file, not to save them the trip. Write the symptom, not the explanation: 「与信が残るのに注文が無い」 beats 「与信成功後〜COMMIT前にプロセスが落ちると、与信は残るが orders に行が無く、夜間スイーパは注文行を見る仕組みなので回収できない」. If a finding genuinely needs the long version, it is important enough to be visible in a diagram — put it there as a `Note` and let the row point at it.

How far you got in verifying a row is information the reviewer needs — a reproduced bug and a hunch deserve different amounts of their attention — but it is *metadata*, so it goes in a mark at the end of the cell rather than in a second sentence:

| Mark | Meaning |
|---|---|
| `✓実行` | ran it and saw the failure |
| `✓確認` | read the code and confirmed it |
| `✓探索(語)` | searched and it genuinely isn't there; the term you searched goes in the parens |
| `⚠未確認` | not verified — add in parens what would settle it |

A row with no mark reads as an unverified guess, so every row gets one.

## Fitting on one page

Rough budget: 4 diagrams, ≤15 nodes each, 2,000–2,500 characters of text outside the diagrams, ≤5 rows in section 5.

When it doesn't fit, in this order: drop context nodes the reader already knows → raise the abstraction level → shorten the section 5 cells → demote what's left to one row of section 5. Dropping something and saying so in one line beats a second page.

## Failure modes

- **A fifth diagram.** Fold it in or demote it to a row in section 5.
- **A class diagram with no members, or a sequence diagram with prose messages.** Both slots exist to carry real identifiers; without them they are decoration.
- **The architecture diagram that buries the change.** Less context, more delta.
- **Paragraphs under the diagrams.** The reader opted out of prose. Two lines, then stop.
- **A table of paragraphs.** Five rows of three sentences each is 700 characters of prose wearing a table's clothes. One sentence per cell, then a mark.
- **Evidence as a second sentence.** 「…を再現済み」 is a mark (`✓実行`), not a clause.
- **"X が無い" without having looked.** Grep first and put the term in `✓探索(語)`, or write `⚠未確認`.
- **Broken Mermaid.** A red error box on GitHub destroys the page's credibility. Run the checker.
- **Confident claims you never checked.** Verify, or write `未確認:`.
- **Redrawing the diff.** One box per changed file, wired in file order, is not a design diagram. Group by meaning.
