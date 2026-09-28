// Builds the Flutter web app into server/public, which `npm start` serves
// next to the API (see src/index.js). Only needed when the app changes.
// The output is committed so reviewers don't need Flutter installed.
//
//   npm run build:web      (requires the Flutter SDK)

import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

const appDir = fileURLToPath(new URL('../../app', import.meta.url));
// --output wants an absolute path.
const outDir = fileURLToPath(new URL('../public', import.meta.url));

// On Windows flutter is a .bat file and can't be found without a shell.
// Passing an args array together with shell: true is deprecated in Node,
// so it's a single command string (path quoted in case of spaces).
const command = [
  'flutter build web --release',
  // Empty base URL: the app calls /api on the same origin it's served from.
  '--dart-define=API_BASE_URL=',
  `--output "${outDir}"`,
].join(' ');

const result = spawnSync(command, { cwd: appDir, stdio: 'inherit', shell: true });
if (result.status !== 0) process.exit(result.status ?? 1);

// CanvasKit loads from Google's CDN (gstatic), so the local ~32 MB copy
// isn't needed and shouldn't end up in the repo.
fs.rmSync(new URL('../public/canvaskit', import.meta.url), {
  recursive: true,
  force: true,
});
console.log(`Web build hazır: ${outDir}`);
