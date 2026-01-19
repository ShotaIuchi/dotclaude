# Commit 運用ルール

## 粒度

- 1 commit = 1 論理的変更
- 動作する状態でのみ commit

## レビュー観点

- commit 単位で差分が理解できるか
- revert しやすいか

## 禁止ファイル

以下のファイルは commit に含めない：

- `.env`, `.env.*`（環境変数・シークレット）
- `credentials.json`, `secrets.*`（認証情報）
- `*.pem`, `*.key`（秘密鍵）
- `node_modules/`, `vendor/`（依存ライブラリ）
