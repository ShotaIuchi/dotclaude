# docs/

ドキュメント出力ディレクトリ。

## 概要

生成されたドキュメントや日本語訳を格納するディレクトリ。
dotclaude自体のドキュメントは`dotclaude/`直下のファイルを参照。

## 構造

```
docs/
├── readme/    # 日本語訳ドキュメント
└── reviews/   # レビュー記録
```

## readme/

dotclaude内の各ファイルの日本語訳を格納。
`docs-sync.md`ルールに従い、元ファイル更新時に同期される。

### 命名規則

| 元ファイル | 日本語訳ファイル |
|-----------|-----------------|
| `CLAUDE.md` | `docs/readme/CLAUDE.md` |
| `commands/{name}.md` | `docs/readme/commands.{name}.md` |
| `rules/{name}.md` | `docs/readme/rules.{name}.md` |
| `agents/{cat}/{name}.md` | `docs/readme/agents.{cat}.{name}.md` |
| `skills/{name}/SKILL.md` | `docs/readme/skills.{name}.md` |

## reviews/

ドキュメントレビューの記録を格納。
`/doc-review`コマンドの出力結果が保存される。

## 関連

- 同期ルール: [`rules/docs-sync.md`](rules/docs-sync.md)
- レビューコマンド: [`commands/doc-review.md`](commands/doc-review.md)
