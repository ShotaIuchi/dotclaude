# scripts/

ユーティリティスクリプトディレクトリ。

## 概要

ワークフロー管理に使用するシェルスクリプトとNode.jsスクリプトを格納。
フックやコマンドから呼び出される。

## 構造

```
scripts/
├── wf-init.sh      # ワークスペース初期化
├── wf-state.sh     # 状態管理ユーティリティ
├── wf-utils.sh     # 共通ユーティリティ関数
├── hooks/          # フック用スクリプト
│   └── ...
├── lib/            # 共通ライブラリ
│   └── ...
└── remote/         # リモート操作用
    └── ...
```

## 主要スクリプト

### wf-init.sh

ワークスペース（`.wf/`ディレクトリ）の初期化を行う。

```bash
./scripts/wf-init.sh
```

### wf-state.sh

`state.json`の読み書きを行うユーティリティ。

```bash
./scripts/wf-state.sh get works.FEAT-123.phase
./scripts/wf-state.sh set works.FEAT-123.status completed
```

### wf-utils.sh

共通のシェル関数を提供。他のスクリプトからsourceして使用。

```bash
source ./scripts/wf-utils.sh
```

## サブディレクトリ

### hooks/

`hooks.json`から呼び出されるフックスクリプト。

### lib/

共通ライブラリ（現在空）。

### remote/

リモートセッション連携用スクリプト。

## 関連

- フック設定: `hooks.json`
- フックルール: [`rules/hooks.md`](rules/hooks.md)
