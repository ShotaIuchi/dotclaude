# templates/

ドキュメントテンプレートディレクトリ。

## 概要

ワークフローで生成されるドキュメントのテンプレートを格納。
各コマンドが対応するテンプレートを参照してドキュメントを生成。

## テンプレート一覧

| ファイル | 用途 | 生成コマンド |
|----------|------|-------------|
| `01_KICKOFF.md` | キックオフドキュメント | wf1-kickoff |
| `02_SPEC.md` | 仕様書 | wf2-spec |
| `03_PLAN.md` | 実装計画 | wf3-plan |
| `04_REVIEW.md` | レビュー記録 | wf4-review |
| `05_IMPLEMENT_LOG.md` | 実装ログ | wf5-implement |
| `06_REVISIONS.md` | 修正記録 | wf6-verify |
| `DOC_REVIEW.md` | ドキュメントレビュー | doc-review |
| `config.example.json` | プロジェクト設定 | wf-init.sh |
| `memory.json` | セッション記憶 | hooks |
| `rules/` | プロジェクト固有ルール | - |

## テンプレートの使われ方

```
/wf1-kickoff issue=123
    ↓
templates/01_KICKOFF.md を読み込み
    ↓
Issueの情報で穴埋め
    ↓
.wf/FEAT-123-xxx/01_KICKOFF.md として保存
```

## カスタマイズ

プロジェクト固有のテンプレートを使用する場合は、`.wf/templates/`にコピーして編集。

```bash
mkdir -p .wf/templates
cp ~/.claude/templates/01_KICKOFF.md .wf/templates/
```

## 関連

- サンプル: [`examples/`](examples/)
- コマンド: [`commands/`](commands/)
