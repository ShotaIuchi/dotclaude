# tests/

テストファイルディレクトリ。

## 概要

dotclaudeのスクリプトやユーティリティのテストを格納。
主にBatsフレームワークを使用したシェルスクリプトのテスト。

## 構造

```
tests/
├── setup.bash           # テスト用セットアップスクリプト
└── test-wf-utils.bats   # wf-utils.shのテスト
```

## ファイル説明

### setup.bash

Batsテストで使用する共通セットアップ。
テスト環境の初期化と共通ヘルパー関数を提供。

### test-wf-utils.bats

`scripts/wf-utils.sh`のユニットテスト。
Batsフレームワークで記述。

## テスト実行

```bash
# Batsがインストールされていることを確認
brew install bats-core

# テスト実行
bats tests/test-wf-utils.bats

# 全テスト実行
bats tests/*.bats
```

## テスト追加

新しいテストファイルは`test-*.bats`の命名規則に従う。

```bash
# 例: wf-state.shのテスト
tests/test-wf-state.bats
```

## 関連

- テスト対象: [`scripts/`](scripts/)
- Bats: https://github.com/bats-core/bats-core
