import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';

const root = process.cwd();
const ignored = new Set(['.git', 'node_modules', '.github']);
const files = [];

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      if (!ignored.has(entry.name)) walk(path.join(dir, entry.name));
    } else if (entry.isFile() && entry.name.toLowerCase().endsWith('.html')) {
      files.push(path.join(dir, entry.name));
    }
  }
}

walk(root);
let checked = 0;
const failures = [];

for (const file of files) {
  const html = fs.readFileSync(file, 'utf8');
  const tags = html.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script\s*>/gi);
  let index = 0;
  for (const match of tags) {
    const attrs = match[1];
    const source = match[2];
    if (/\bsrc\s*=/i.test(attrs) || /\btype\s*=\s*["']?application\/(?:json|ld\+json)/i.test(attrs)) continue;
    index += 1;
    try {
      new vm.Script(source, { filename: path.relative(root, file) + '#inline-script-' + index });
      checked += 1;
    } catch (error) {
      failures.push(path.relative(root, file) + ' inline script ' + index + ': ' + error.message);
    }
  }
}

console.log('Checked ' + checked + ' inline JavaScript blocks across ' + files.length + ' HTML files.');
if (failures.length) {
  console.error(failures.join('\n'));
  process.exitCode = 1;
}
