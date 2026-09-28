import fs from 'node:fs';
import path from 'node:path';

// Relative time in the seed: "USE_NOW_PLUS_21H32M" means now + 21h 32m.
const NOW_PLUS = /^USE_NOW_PLUS_(\d+)H(\d+)M$/;

// Works on a copy so the seed itself never changes and reset always
// starts from the same state.
export function materializeSeed(seed, now = new Date()) {
  const data = structuredClone(seed);
  for (const offer of data.offers) {
    const match = NOW_PLUS.exec(offer.expiresAt);
    if (!match) continue;
    const minutes = Number(match[1]) * 60 + Number(match[2]);
    offer.expiresAt = new Date(now.getTime() + minutes * 60_000).toISOString();
  }
  return data;
}

// Small JSON file store. If the file exists we load it, so writes survive
// a server restart. If not, it's built from the seed, which means a fresh
// clone always starts with offers at "21 saat 32 dakika".
//
// Without `file` it stays in memory (used by the tests).
export function createStore({ seed, file = null, now = () => new Date() }) {
  let data;

  // Write to a temp file and rename, so a crash mid-write doesn't leave a
  // half-written db.json.
  function persist() {
    if (!file) return;
    fs.mkdirSync(path.dirname(file), { recursive: true });
    const tmp = `${file}.tmp`;
    fs.writeFileSync(tmp, JSON.stringify(data, null, 2));
    fs.renameSync(tmp, file);
  }

  function reset() {
    data = materializeSeed(seed, now());
    persist();
  }

  if (file && fs.existsSync(file)) {
    data = JSON.parse(fs.readFileSync(file, 'utf8'));
  } else {
    reset();
  }

  return {
    // Returns a copy; callers can't change the store by accident.
    // write() is the only way in.
    read: () => structuredClone(data),

    // mutate runs on a draft that's only saved if it doesn't throw.
    // POST /offers relies on this for its all-or-nothing behavior.
    write(mutate) {
      const draft = structuredClone(data);
      const result = mutate(draft);
      data = draft;
      persist();
      return result;
    },

    reset,
  };
}
