# Agent Team スコープ検出

全Agent Teamスキル共通の `$ARGUMENTS` パースルール。
Lead Agentはサブエージェント起動前に分析対象を確定する必要がある。

## サポートするスコープ

| スコープ | フラグ | 取得コマンド | 例 |
|----------|--------|-------------|-----|
| PR | `--pr <N>` | `gh pr diff <N>` + `gh pr view <N> --json title,body,files` | `/review-team --pr 42` |
| Issue | `--issue <N>` | `gh issue view <N> --json title,body,comments` | `/debug-team --issue 123` |
| コミット | `--commit <ref>` | `git show <ref>` or `git diff <A>..<B>` | `/review-team --commit HEAD~3..HEAD` |
| ステージ済み差分 | `--staged` | `git diff --staged` | `/review-team --staged` |
| 未ステージ差分 | `--diff` | `git diff` | `/test-team --diff` |
| ブランチ差分 | `--branch <name>` | `git diff main...<name>` | `/review-team --branch feature/auth` |
| ファイル/ディレクトリ | パス（自動検出） | `Read` / `Glob` | `/test-team src/auth/` |
| フリーテキスト | （残余テキスト） | 指示・コンテキストとして使用 | `/debug-team login fails on timeout` |

## 自動検出ルール（フラグなしの場合）

以下の順序で判定し、最初に一致した時点で確定する：

```
1. --flag 付き         -> フラグに従う（最優先）
2. パス形式の文字列    -> ファイル/ディレクトリ（`.` or `/` を含む）
3. 数値のみ            -> 曖昧：ユーザーに PR / Issue / その他 を確認
4. その他のテキスト    -> フリーテキスト（指示として使用）
5. 引数なし            -> 不明：ユーザーに対象を質問
```

## 曖昧・引数なし時の確認

入力が空または曖昧な場合、Lead Agentは以下を提示する：

```
対象を指定してください:
- PR番号（例: --pr 42）
- Issue番号（例: --issue 123）
- コミット（例: --commit HEAD~3..HEAD）
- 現在の差分（--diff / --staged）
- ブランチ差分（例: --branch feature/auth）
- ファイルパス（例: src/auth/）
```

### 数値のみの場合

引数が数値のみ（例: `42`）の場合、Lead Agentは以下を確認する：

```
"42" は複数の対象に該当する可能性があります。どれを指しますか？
- PR #42       (--pr 42)
- Issue #42    (--issue 42)
- その他（具体的に指定してください）
```

## フラグパースルール

- フラグは大文字小文字を区別し、`--` プレフィックスを使用
- フラグは次のホワイトスペース区切りトークンを値として消費（`--diff` と `--staged` はブーリアンで値なし）
- 未知のフラグはフリーテキストとして扱う
- 複数フラグの併用可能：`--pr 42 --commit HEAD~3..HEAD`（PRが主スコープ）
- フラグパース後の残余トークンはフリーテキストコンテキストになる

## チームスキルとの統合

各チームのSKILL.mdには **Step 0: Scope Detection** フェーズが含まれ、本ドキュメントを参照する。
Lead AgentはStep 0を完了した後、チーム固有の分析（Step 1）に進む。
