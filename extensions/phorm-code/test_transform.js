// Quick integration test — runs parser + transformer on a sample file
const { parseFile } = require('./out/parser');
const { transformFile } = require('./out/transformer');
const fs = require('fs');

const source = fs.readFileSync('./test_input.dart', 'utf8');
const parsed = parseFile(source, 'test_input');

console.log('=== PARSED CLASSES ===');
for (const cls of parsed.classes) {
  console.log(`  Class: ${cls.name}`);
  console.log(`    alreadyConverted: ${cls.alreadyConverted}`);
  console.log(`    hasIdField: ${cls.hasIdField}`);
  console.log(`    idField type: ${cls.idField?.type ?? 'none'}`);
  console.log(`    fields: ${cls.fields.map(f => `${f.type} ${f.name}${f.isNullable ? '?' : ''}`).join(', ')}`);
}

console.log('\n=== TRANSFORMED OUTPUT ===\n');
const result = transformFile(parsed);
console.log(result);
