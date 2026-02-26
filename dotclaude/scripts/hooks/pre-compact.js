#!/usr/bin/env node
/**
 * PreCompact Hook
 *
 * コンテキストコンパクション前に重要な状態を保存する。
 * コンパクションで失われる情報を memory.json に退避。
 *
 * Reads active_work from local.json, per-work state from docs/wf/<work-id>/state.json.
 */

const fs = require('fs');
const path = require('path');

const LOCAL_FILE = '.wf/local.json';
const MEMORY_FILE = '.wf/memory.json';
const DOCS_WF_DIR = 'docs/wf';

function main() {
  let input = '';

  process.stdin.on('data', chunk => {
    input += chunk;
  });

  process.stdin.on('end', () => {
    const cwd = process.cwd();
    const localPath = path.join(cwd, LOCAL_FILE);
    const memoryPath = path.join(cwd, MEMORY_FILE);
    const wfDir = path.join(cwd, '.wf');

    // .wf ディレクトリが存在する場合のみ処理
    if (fs.existsSync(wfDir)) {
      try {
        let memory = {};

        // 既存の memory.json を読み込み
        if (fs.existsSync(memoryPath)) {
          memory = JSON.parse(fs.readFileSync(memoryPath, 'utf8'));
        }

        // コンパクション時刻を記録
        memory.last_compact = new Date().toISOString();
        memory.compact_count = (memory.compact_count || 0) + 1;

        // local.json から active_work を取得
        let activeWork = null;

        if (fs.existsSync(localPath)) {
          try {
            const local = JSON.parse(fs.readFileSync(localPath, 'utf8'));
            activeWork = local.active_work;
          } catch (e) {
            // ignore
          }
        }

        // Fallback: 旧形式の state.json
        if (!activeWork) {
          const statePath = path.join(cwd, '.wf/state.json');
          if (fs.existsSync(statePath)) {
            try {
              const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
              activeWork = state.active_work;
            } catch (e) {
              // ignore
            }
          }
        }

        if (activeWork) {
          memory.context = memory.context || {};
          memory.context.active_work = activeWork;

          // Per-work state からフェーズ情報を同期
          const workStatePath = path.join(cwd, DOCS_WF_DIR, activeWork, 'state.json');

          if (fs.existsSync(workStatePath)) {
            try {
              const work = JSON.parse(fs.readFileSync(workStatePath, 'utf8'));
              memory.context.current_phase = work.current;
              memory.context.next_phase = work.next;
            } catch (e) {
              // ignore
            }
          } else {
            // Fallback: 旧形式
            const statePath = path.join(cwd, '.wf/state.json');
            if (fs.existsSync(statePath)) {
              try {
                const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
                const work = state.works && state.works[activeWork];
                if (work) {
                  memory.context.current_phase = work.current;
                  memory.context.next_phase = work.next;
                }
              } catch (e) {
                // ignore
              }
            }
          }
        }

        // 保存
        fs.writeFileSync(memoryPath, JSON.stringify(memory, null, 2));

        console.error('[Hook] Pre-compact: State saved to ' + MEMORY_FILE);
        console.error('[Hook] Compact count: ' + memory.compact_count);
      } catch (e) {
        // エラーは無視
      }
    }

    // 入力をそのまま出力
    console.log(input);
  });
}

main();
