// Flutter web build'ini alıp server/public'e koyar: `npm start` onu API
// ile aynı adresten sunuyor (bkz. src/index.js). Yalnızca uygulama
// değiştiğinde çalıştırılır; çıktı repoya commit'leniyor ki değerlendirici
// Flutter kurmadan açabilsin.
//
//   npm run build:web      (Flutter SDK gerekir)

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const appDir = fileURLToPath(new URL('../../app', import.meta.url));
// --output mutlak yol istiyor.
const outDir = fileURLToPath(new URL('../public', import.meta.url));

// Windows'ta flutter bir .bat dosyası; shell olmadan bulunamıyor. Shell
// ile argüman dizisi verilmesi Node'da kullanımdan kalkıyor, o yüzden tek
// komut satırı (yol tırnaklı: boşluk içerebilir).
const command = [
  'flutter build web --release',
  // Boş adres: uygulama API'ye kendi sunulduğu adresten (/api) gider.
  '--dart-define=API_BASE_URL=',
  `--output "${outDir}"`,
].join(' ');

const result = spawnSync(command, { cwd: appDir, stdio: 'inherit', shell: true });
if (result.status !== 0) process.exit(result.status ?? 1);

// CanvasKit tarayıcıya Google CDN'inden (gstatic) geliyor; yerel kopyası
// (~32 MB) sunulmuyor, repoya da girmesin.
fs.rmSync(new URL('../public/canvaskit', import.meta.url), {
  recursive: true,
  force: true,
});
console.log(`Web build hazır: ${outDir}`);
