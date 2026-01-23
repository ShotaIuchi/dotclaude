#!/usr/bin/env node
/**
 * SessionEnd Hook
 *
 * セッション終了時に状態を保存する。
 * - .wf/memory.json に記憶を保存
 *
 * 注: このスクリプトは stdin から入力を受け取り、
 * memory.json の更新はユーザーの明示的な指示がある場合のみ行う。
 * 自動保存は last_session のタイムスタンプのみ。
 */

const fs = require('fs');
const path = require('path');

const MEMORY_FILE = '.wf/memory.json';

function main() {
  let input = '';

  process.stdin.on('data', chunk => {
    input += chunk;
  });

  process.stdin.on('end', () => {
    const cwd = process.cwd();
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

        // セッション終了時刻を記録
        memory.last_session = new Date().toISOString();

        // セッション回数をインクリメント
        memory.session_count = (memory.session_count || 0) + 1;

        // 保存
        fs.writeFileSync(memoryPath, JSON.stringify(memory, null, 2));

        console.error('[Session] State saved to ' + MEMORY_FILE);
      } catch (e) {
        // エラーは無視（.wf が無いプロジェクトでは何もしない）
      }
    }

    // 入力をそのまま出力（パイプライン継続）
    console.log(input);
  });
}

main();
