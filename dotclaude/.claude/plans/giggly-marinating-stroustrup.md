# wf7-pr 分離計画

## 概要

wf6-verify の PR 作成機能を wf7-pr として分離し、auto モードで自動 PR 作成を可能にする。

## 設計方針

| 項目 | 変更前 | 変更後 |
|------|--------|--------|
| wf6-verify | 検証 + PR作成 | 検証のみ |
| wf7-pr | なし | PR作成/更新 |
| 遷移 | wf6 → complete | wf6 → wf7 → complete |

## 実装計画

### Step 1: wf7-pr スキル新規作成

**ファイル**: `skills/wf7-pr/SKILL.md`

```
/wf7-pr           # PR作成
/wf7-pr update    # PR更新
```

責務:
- 検証パス確認
- ブランチpush
- PRタイトル生成（Issue紐づけ `(#N)`）
- `gh pr create` でPR作成
- state.json に PR URL 記録
- `next: "complete"` に設定

### Step 2: wf6-verify 更新

**ファイル**: `skills/wf6-verify/SKILL.md`

変更:
- `pr`, `update` サブコマンド削除
- PR作成セクション（5, 6）削除
- 検証成功時: `next: "wf7-pr"` に設定
- argument-hint を空に

### Step 3: wf0-nextstep 更新

**ファイル**: `skills/wf0-nextstep/SKILL.md`

遷移テーブル追加:
```
| `next` value | Action |
|--------------|--------|
| `"wf7-pr"`   | Execute `/wf7-pr` |
| `"complete"` + no PR | Suggest `/wf7-pr` |
```

### Step 4: 日本語ドキュメント

新規:
- `docs/readme/skills.wf7-pr.md`

更新:
- `docs/readme/skills.wf6-verify.md` (PR関連削除)

### Step 5: auto-daemon.sh 確認

変更不要。wf0-nextstep が wf7-pr を呼び出すため、自動的にPR作成まで完了する。

## 修正対象ファイル

| ファイル | 操作 |
|----------|------|
| `skills/wf7-pr/SKILL.md` | 新規作成 |
| `skills/wf6-verify/SKILL.md` | 更新 |
| `skills/wf0-nextstep/SKILL.md` | 更新 |
| `docs/readme/skills.wf7-pr.md` | 新規作成 |
| `docs/readme/skills.wf6-verify.md` | 更新 |

## state.json 遷移

```
wf5-implement → wf6-verify → wf7-pr → complete
                ↳ next: "wf7-pr"  ↳ next: "complete"
```

## 検証方法

1. `/wf6-verify` 実行後、`state.json` の `next` が `"wf7-pr"` になることを確認
2. `/wf0-nextstep` が `/wf7-pr` を正しく呼び出すことを確認
3. `/wf7-pr` がPRを作成し、Issue番号が紐づくことを確認
4. auto モードで Issue → PR まで自動完了することを確認
