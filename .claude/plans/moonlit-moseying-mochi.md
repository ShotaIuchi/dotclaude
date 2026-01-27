# Plan: commands/ から skills/ への全面移行

## 概要

Claude Code の commands/ と skills/ が統合されたため、重複を解消し skills/ に統一する。

## 背景

- `commands/*.md` と `skills/{name}/SKILL.md` は両方ともスラッシュコマンドとして認識される
- 同じ名前が両方にあると重複して読み込まれる
- skills/ の方が高度な機能（allowed-tools, context: fork 等）をサポート

## 現状

### commands/ (14ファイル) - 移行対象
- wf0-config.md
- wf0-nextstep.md
- wf0-nexttask.md (重複)
- wf0-promote.md
- wf0-remote.md
- wf0-restore.md
- wf0-schedule.md (重複)
- wf0-status.md
- wf1-kickoff.md
- wf2-spec.md
- wf3-plan.md
- wf4-review.md
- wf5-implement.md
- wf6-verify.md

### skills/ (既存) - 維持
- wf0-nexttask/SKILL.md
- wf0-schedule/SKILL.md
- android-architecture/SKILL.md
- ios-architecture/SKILL.md
- kmp-architecture/SKILL.md
- aws-sam/SKILL.md

## 実装ステップ

### Step 1: 既存 skills/ の内容を確認
wf0-schedule と wf0-nexttask の SKILL.md が commands/ と同等の内容か確認。
不足があれば commands/ から内容をマージ。

### Step 2: 新規 skills/ ディレクトリ作成 (12個)
```
skills/wf0-config/SKILL.md
skills/wf0-nextstep/SKILL.md
skills/wf0-promote/SKILL.md
skills/wf0-remote/SKILL.md
skills/wf0-restore/SKILL.md
skills/wf0-status/SKILL.md
skills/wf1-kickoff/SKILL.md
skills/wf2-spec/SKILL.md
skills/wf3-plan/SKILL.md
skills/wf4-review/SKILL.md
skills/wf5-implement/SKILL.md
skills/wf6-verify/SKILL.md
```

### Step 3: commands/*.md を skills/ にコピー・変換
- commands/wf*.md の内容を skills/wf*/SKILL.md にコピー
- frontmatter 形式を skills 用に調整（必要に応じて）

### Step 4: commands/wf*.md を削除 (14ファイル)
重複を解消するため commands/ からワークフローコマンドを削除。

### Step 5: skills/README.md を更新
新しいスキル一覧を反映。

### Step 6: docs-sync ルールに従い日本語ドキュメント更新
skills.{name}.md 形式で docs/readme/ を更新。

## 変換例

### Before: commands/wf0-status.md
```markdown
---
description: Display current workflow status
argument-hint: "[work-id]"
---

# /wf0-status
...
```

### After: skills/wf0-status/SKILL.md
```markdown
---
name: wf0-status
description: Display current workflow status
---

# /wf0-status
...
```

## 検証方法

1. `/wf0-status` が正しく動作することを確認
2. スキル一覧で重複がないことを確認
3. 全ての wf コマンドが呼び出せることを確認

## 関連ファイル

- `dotclaude/commands/wf*.md` - 移行元（削除）
- `dotclaude/skills/*/SKILL.md` - 移行先
- `dotclaude/skills/README.md` - 更新
- `dotclaude/docs/readme/` - ドキュメント更新
