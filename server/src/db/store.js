import fs from 'node:fs';
import path from 'node:path';

// Seed'deki göreli süre: "USE_NOW_PLUS_21H32M" → şimdi + 21 saat 32 dakika.
const NOW_PLUS = /^USE_NOW_PLUS_(\d+)H(\d+)M$/;

// Seed'i çalışma verisine çevirir. Seed'in KENDİSİNE dokunmaz (kopya
// üzerinde çalışır): reset her seferinde aynı başlangıcı üretebilmeli.
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

// JSON dosyası üzerinde basit veri deposu.
//
// Dosya varsa ondan okunur: accept/reject gibi yazmalar sunucu yeniden
// başlasa da KALICI. Yoksa seed'den üretilir. Süreler bu anda
// hesaplandığı için taze klonda talepler hep "21 saat 32 dakika" ile başlar.
//
// `file` verilmezse yalnızca bellekte çalışır (testler için).
export function createStore({ seed, file = null, now = () => new Date() }) {
  let data;

  // Önce geçici dosyaya yazıp sonra yerine taşıyor: yazma yarıda kesilirse
  // db.json yarım kalmaz, eski hâli durur.
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
    // Kopya döner: çağıran taraf okuduğu veriyi değiştirse bile depo
    // etkilenmez. Tek yazma yolu write().
    read: () => structuredClone(data),

    // Mutasyon bir TASLAK üzerinde çalışır ve ancak hatasız biterse
    // kaydedilir. Hata fırlatırsa hiçbir değişiklik yazılmaz. POST
    // /offers'taki "biri çakışırsa hiçbiri yazılmaz" kuralı buna dayanıyor.
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
