# Claude Code Reference

公式ドキュメントへのポインタとプロジェクト固有の規約。

---

## 公式ドキュメント

### Agent Skills（platform.claude.com）

Skills の設計思想・アーキテクチャ・ベストプラクティスの包括的ガイド。

| Topic | URL |
|-------|-----|
| Overview | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview |
| Best Practices | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices |
| Quickstart | https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart |

3段階ローディング、progressive disclosure、evaluation-driven development 等。

### Agent SDK（platform.claude.com）

SDK でのサブエージェント定義・プログラマティック制御。

| Topic | URL |
|-------|-----|
| SDK Overview | https://platform.claude.com/docs/en/agent-sdk/overview |
| Subagents (SDK) | https://platform.claude.com/docs/en/agent-sdk/subagents |
| Hooks (SDK) | https://platform.claude.com/docs/en/agent-sdk/hooks |

### Claude Code（code.claude.com）

`.claude/` ディレクトリ構成の実装リファレンス。

| Topic | 対応する `.claude/` 設定 | URL |
|-------|-------------------------|-----|
| Skills | `skills/*/SKILL.md` | https://code.claude.com/docs/en/skills |
| Sub-agents | `agents/*.md` | https://code.claude.com/docs/en/sub-agents |
| Memory & CLAUDE.md | `CLAUDE.md`, `rules/*.md` | https://code.claude.com/docs/en/memory |
| Hooks | `settings.json` の hooks | https://code.claude.com/docs/en/hooks |
| Hooks Guide | 同上（実践ガイド） | https://code.claude.com/docs/en/hooks-guide |
| Settings | `settings.json`, `settings.local.json` | https://code.claude.com/docs/en/settings |
| Plugins | `plugins/` | https://code.claude.com/docs/en/plugins |
| IAM & Permissions | permissions 設定 | https://code.claude.com/docs/en/iam |
| Best Practices | 全般 | https://code.claude.com/docs/en/best-practices |
| LLMs Full Index | 全ページインデックス | https://code.claude.com/docs/llms.txt |

---

## `.claude/` ディレクトリと公式ドキュメントの対応

| Path | 公式リファレンス |
|------|-----------------|
| `CLAUDE.md` | [Memory](https://code.claude.com/docs/en/memory) |
| `rules/*.md` | [Memory > Modular rules](https://code.claude.com/docs/en/memory#modular-rules-with-clauderules) |
| `skills/*/SKILL.md` | [Skills](https://code.claude.com/docs/en/skills) + [Agent Skills Overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) |
| `agents/*.md` | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| `settings.json` | [Settings](https://code.claude.com/docs/en/settings) |
| `settings.local.json` | [Settings](https://code.claude.com/docs/en/settings) |
| `hooks.json` (※) | [Hooks](https://code.claude.com/docs/en/hooks) |
| `plugins/` | [Plugins](https://code.claude.com/docs/en/plugins) |

※ hooks は `settings.json` 内で定義するのが現在の標準。

---

## プロジェクト固有の規約

公式ドキュメントでカバーされない本プロジェクト独自のルール:

→ [best-practices.md](best-practices.md)

- ワークフロースキルの命名規則（wf0-wf6）
- Processing セクションの構成
- 完了メッセージの形式
- スキル本文の制限（500行）
- エラーハンドリングのパターン
