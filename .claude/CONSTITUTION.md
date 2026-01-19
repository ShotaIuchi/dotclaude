# dotclaude プロジェクト固有ルール

グローバル憲法（dotclaude/CONSTITUTION.md）に加えて、このプロジェクト固有のルールを定義する。

---

## 必須ドキュメント

| 追加対象 | 必須ドキュメント |
|---------|-----------------|
| 新カテゴリ（references/{group}/{category}/） | index.md |
| 新スキル（skills/{name}/） | SKILL.md |
| 新エージェント（agents/{type}/{name}/） | AGENT.md |
| 新コマンド（commands/） | ファイル先頭にコメントで説明 |

---

## 更新必須

| 追加対象 | 更新対象 |
|---------|---------|
| references/ 内のファイル | references/INDEX.md |
| skills/ 内のスキル | 参照する references のパス |

---

## 命名規則

### ファイル名
- ケバブケース: `clean-architecture.md`, `sam-template.md`
- index ファイル: `index.md`（大文字は INDEX.md のみ）

### ディレクトリ名
- ケバブケース: `android-architecture/`, `aws-sam/`
- グループは複数形: `platforms/`, `languages/`, `services/`

### frontmatter 形式
```yaml
---
name: 英語タイトル
description: 英語説明（Claude が参照するため）
references:
  - path: 相対パス
---
```

---

## 依存関係チェックリスト

- [ ] 参照先ファイルが存在するか
- [ ] 相対パスが正しいか
- [ ] 参照元（INDEX.md, SKILL.md）を更新したか
- [ ] 壊れたリンクがないか
