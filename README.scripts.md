# scripts/

ユーティリティスクリプトディレクトリ。

## 概要

ワークフロー管理に使用するシェルスクリプトとNode.jsスクリプトを格納。
フックやコマンドから呼び出される。

## 構造

```
scripts/
├── wf-init.sh              # ワークスペース初期化
├── wf-state.sh             # 状態管理ユーティリティ
├── wf-utils.sh             # 共通ユーティリティ関数
├── hooks/                  # フック用スクリプト
│   ├── session-start.js    # セッション開始時
│   ├── session-end.js      # セッション終了時
│   └── pre-compact.js      # コンパクション前
├── remote/                 # リモート操作用（旧wf系）
│   ├── remote-daemon.sh    # リモート監視デーモン
│   └── remote-utils.sh     # リモート操作ユーティリティ
└── ghwf/                   # GitHub専用ワークフロー
    ├── ghwf-daemon.sh      # ラベル監視デーモン
    └── ghwf-utils.sh       # ghwf共通関数（リトライ対応）
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

| スクリプト | タイミング |
|------------|------------|
| `session-start.js` | セッション開始時にmemory.json読込 |
| `session-end.js` | セッション終了時にmemory.json保存 |
| `pre-compact.js` | コンパクション前にmemory.json保存 |

### remote/

リモートワークフロー操作用スクリプト（旧wf系）。

| スクリプト | 目的 |
|------------|------|
| `remote-daemon.sh` | GitHub Issueコメント監視デーモン |
| `remote-utils.sh` | リモート操作共通関数 |

### ghwf/

GitHub専用ワークフロー（ラベルベース制御）。

| スクリプト | 目的 |
|------------|------|
| `ghwf-daemon.sh` | ghwf:*ラベル監視デーモン |
| `ghwf-utils.sh` | ghwf共通関数（リトライ・権限チェック） |

環境変数:

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `POLL_INTERVAL` | 60 | ポーリング間隔（秒） |
| `MAX_STEPS_PER_SESSION` | 10 | セッションあたり最大ステップ数 |
| `GHWF_RETRY_MAX` | 3 | API呼び出しリトライ回数 |
| `GHWF_RETRY_DELAY` | 5 | リトライ初期遅延（秒） |

## 関連

- フック設定: `hooks.json`
- フックルール: [`rules/hooks.md`](dotclaude/rules/hooks.md)
