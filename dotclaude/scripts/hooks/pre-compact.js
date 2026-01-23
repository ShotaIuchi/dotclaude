#!/usr/bin/env node
/**
 * PreCompact Hook
 *
 * コンテキストコンパクション前に重要な状態を保存する。
 * コンパクションで失われる情報を memory.json に退避。
 */

const fs = require('fs');
const path = require('path');

const MEMORY_FILE = '.wf/memory.json';
const STATE_FILE = '.wf/state.json';

function main() {
  let input = '';

  process.stdin.on('data', chunk => {
    input += chunk;
  });

  process.stdin.on('end', () => {
    const cwd = process.cwd();
    const memoryPath = path.join(cwd, MEMORY_FILE);
    const statePath = path.join(cwd, STATE_FILE);
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

        // state.json から現在の状態を同期
        if (fs.existsSync(statePath)) {
          const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
          if (state.active_work) {
            memory.context = memory.context || {};
            memory.context.active_work = state.active_work;

            const work = state.works && state.works[state.active_work];
            if (work) {
              memory.context.current_phase = work.current;
              memory.context.next_phase = work.next;
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
