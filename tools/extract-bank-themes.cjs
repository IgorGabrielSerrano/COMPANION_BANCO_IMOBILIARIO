const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'build/index.html'), 'utf8');
const literal = html.match(/const BANK_THEMES = ([\s\S]*?);\s*let appliedBankTheme/)[1];
// Evaluate only the locally authored palette object, not the app's runtime.
const themes = Function(`return (${literal});`)();
fs.writeFileSync(path.join(root, 'godot-web/bank_themes.json'), JSON.stringify(themes, null, 2) + '\n');
