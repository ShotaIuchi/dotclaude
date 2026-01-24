# Agent: doc-writer

## 概要

コードやモジュールのドキュメントを作成するエージェント。README、API ドキュメント、アーキテクチャ説明、使用ガイドなど、様々な形式に対応している。

## メタデータ

| 項目 | 値 |
|------|-----|
| ID | doc-writer |
| Base Type | general |
| Category | task |

## 入力パラメータ

| パラメータ | 必須 | デフォルト | 説明 |
|-----------|------|-----------|------|
| `target` | 必須 | - | ドキュメント対象のパス |
| `type` | 必須 | - | ドキュメント種類: `"readme"` / `"api"` / `"architecture"` / `"usage"` |
| `audience` | 任意 | `"developer"` | 対象読者: `"developer"` / `"user"` / `"maintainer"` |
| `language` | 任意 | `"en"` | 出力言語: `"en"` / `"ja"` |

## 機能（type 別）

| type | 機能 | 内容 |
|------|------|------|
| `readme` | README 作成 | プロジェクト概要、セットアップ手順、基本的な使い方 |
| `api` | API ドキュメント作成 | 関数/クラスリファレンス、パラメータ説明、使用例 |
| `architecture` | アーキテクチャドキュメント作成 | システム構成、コンポーネント関係、データフロー |
| `usage` | 使用ガイド作成 | ステップバイステップのチュートリアル、一般的な使用パターン |

## 制約事項

- 指定された言語で出力（デフォルト: 英語）
- Markdown 形式で出力
- 既存ドキュメントのスタイルに準拠
- コードは変更せず、ドキュメントのみ作成

## 処理フロー

1. **対象分析**: ディレクトリ構造とソースコードを確認
2. **コード読解**: エクスポートされた関数/クラス、シグネチャ、既存コメントを抽出
3. **ドキュメント作成**: type に応じたフォーマットで生成
4. **一貫性確認**: 既存ドキュメントとのスタイル・用語の整合性を確認
5. **ファイル配置**: 適切な場所に出力

## 出力ファイル配置

| type | デフォルト場所 | ファイル名 |
|------|---------------|-----------|
| `readme` | `<target>/` | `README.md` |
| `api` | `docs/<target>/` | `API.md` |
| `architecture` | `docs/` | `ARCHITECTURE.md` |
| `usage` | `docs/` | `USAGE.md` または `GUIDE.md` |

## 使用例

```
# README 作成
target="src/auth"
type="readme"
audience="developer"

# API ドキュメント作成（日本語）
target="lib/utils"
type="api"
language="ja"

# アーキテクチャドキュメント作成
target="."
type="architecture"
audience="maintainer"
```

## 出力形式

```markdown
## Documentation Creation Results

### Target
- **Path**: <target>
- **Type**: <type>
- **Audience**: <audience>

### Generated Documentation
---
<生成されたドキュメント>
---

### File Placement Suggestions
| File | Location | Description |
|------|----------|-------------|
| <filename> | <path> | <purpose> |
```
