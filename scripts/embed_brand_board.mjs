import fs from 'node:fs';
import path from 'node:path';

const [inputPath, outputPath] = process.argv.slice(2);

if (!inputPath || !outputPath) {
  throw new Error('Uso: node scripts/embed_brand_board.mjs entrada.svg saida.svg');
}

const sourceDirectory = path.dirname(path.resolve(inputPath));
let svg = fs.readFileSync(inputPath, 'utf8');

if (!svg.includes('xmlns:xlink=')) {
  svg = svg.replace(
    'xmlns="http://www.w3.org/2000/svg"',
    'xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"',
  );
}

svg = svg.replace(/(?:xlink:)?href="([^"#]+\.(?:svg|png|jpg|jpeg))"/gi, (_match, href) => {
  const filePath = path.resolve(sourceDirectory, href);
  const extension = path.extname(filePath).toLowerCase();
  const mime = extension === '.svg'
    ? 'image/svg+xml'
    : extension === '.png'
      ? 'image/png'
      : 'image/jpeg';
  const encoded = fs.readFileSync(filePath).toString('base64');
  return `xlink:href="data:${mime};base64,${encoded}"`;
});

svg = svg.replace(/\shref="data:/g, ' xlink:href="data:');

fs.writeFileSync(outputPath, svg);
