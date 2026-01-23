#!/usr/bin/env node
/**
 * SessionStart Hook
 *
 * セッション開始時に前回のコンテキストを復元する。
 * - .wf/memory.json から記憶を読み込み
 * - state.json から現在のワークフロー状態を表示
 */

const fs = require('fs');
const path = require('path');

const MEMORY_FILE = '.wf/memory.json';
const STATE_FILE = '.wf/state.json';

function main() {
  const cwd = process.cwd();
  const memoryPath = path.join(cwd, MEMORY_FILE);
  const statePath = path.join(cwd, STATE_FILE);

  const output = [];

  // state.json から現在のワークフロー状態を取得
  if (fs.existsSync(statePath)) {
    try {
      const state = JSON.parse(fs.readFileSync(statePath, 'utf8'));
      const activeWork = state.active_work;

      if (activeWork && state.works && state.works[activeWork]) {
        const work = state.works[activeWork];
        output.push('[Session] Active work: ' + activeWork);
        output.push('[Session] Current phase: ' + (work.current || 'unknown'));
        output.push('[Session] Next phase: ' + (work.next || 'unknown'));
      }
    } catch (e) {
      // state.json の読み込みエラーは無視
    }
  }

  // memory.json から前回の記憶を復元
  if (fs.existsSync(memoryPath)) {
    try {
      const memory = JSON.parse(fs.readFileSync(memoryPath, 'utf8'));

      if (memory.last_session) {
        output.push('[Session] Last session: ' + memory.last_session);
      }

      if (memory.context && Object.keys(memory.context).length > 0) {
        output.push('[Session] Restored context:');

        if (memory.context.tech_stack && memory.context.tech_stack.length > 0) {
          output.push('  Tech stack: ' + memory.context.tech_stack.join(', '));
        }

        if (memory.context.current_task) {
          output.push('  Current task: ' + memory.context.current_task);
        }

        if (memory.context.progress) {
          output.push('  Progress: ' + memory.context.progress);
        }
      }

      if (memory.decisions && memory.decisions.length > 0) {
        output.push('[Session] Previous decisions:');
        memory.decisions.slice(-5).forEach(d => {
          output.push('  - ' + d);
        });
      }

      if (memory.blockers && memory.blockers.length > 0) {
        output.push('[Session] Known blockers:');
        memory.blockers.forEach(b => {
          output.push('  - ' + b);
        });
      }

    } catch (e) {
      // memory.json の読み込みエラーは無視
    }
  }

  // 出力があれば表示
  if (output.length > 0) {
    console.error(output.join('\n'));
  }
}

main();
