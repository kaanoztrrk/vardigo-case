# Vardigo Case

[![Son commit](https://img.shields.io/github/last-commit/kaanoztrrk/vardigo-case?label=son%20commit)](https://github.com/kaanoztrrk/vardigo-case/commits/main)
[![Commit sayısı](https://img.shields.io/github/commit-activity/t/kaanoztrrk/vardigo-case?label=commit)](https://github.com/kaanoztrrk/vardigo-case/commits/main)
[![Haftalık](https://img.shields.io/github/commit-activity/w/kaanoztrrk/vardigo-case?label=bu%20hafta)](https://github.com/kaanoztrrk/vardigo-case/graphs/commit-activity)

İki ekran (Eşleşen Personeller / Görüşme Talepleri) + REST API.

| Klasör | İçerik |
|---|---|
| `app/` | Flutter web istemci (390×844 telefon çerçevesi) |
| `server/` | Node + Express REST API, JSON dosya veritabanı |

Geliştirme süreci adım adım commit'lerde:
[commit geçmişi](https://github.com/kaanoztrrk/vardigo-case/commits/main) ya da
yerelde `git log --oneline --reverse`.

Yapay zekâ kullanımı ve süreç notu: [SUREC.txt](SUREC.txt) — mimari ve
kararlar benim; kodun yazımını, kendi mimari kurallarımla yapılandırdığım
Claude Code hızlandırdı.

## Hızlı başlangıç

Gereken: **Node 20+** ve internet (tarayıcı Flutter'ın çizim motorunu
CDN'den yüklüyor). Flutter kurmak gerekmiyor — uygulamanın hazır build'i
repoda (`server/public/`).

```bash
npm install     # sunucu bağımlılıklarını da kurar
npm start       # → http://localhost:3000  (uygulama + API)
```

Açılınca:

- Sayfanın üstündeki **İşveren | İş arayan** anahtarı iki demo hesap
  arasında geçiriyor (case'de giriş ekranı yok; rol seçmek giriş yapmak).
- **İşveren** → Eşleşen Personeller: aday seç → *Görüşme Talebi Gönder*.
- **İş arayan** → Görüşme Talepleri: gönderilen talep *Bekleyen*'de;
  *İlgileniyorum / İlgilenmiyorum* → *Cevaplanan*.
- *Süresi Dolan*'ı beklemeden görmek ve veriyi sıfırlamak için
  [aşağıdaki](#uç-noktalar) `POST /api/dev/expire/:id` ve `POST /api/dev/reset`.

Port değiştirmek için: `PORT=4000 npm start` (Windows PowerShell:
`$env:PORT=4000; npm start`).

### Geliştirme

```bash
# API (dosya değişince yeniden başlar) → http://localhost:3000/api
cd server && npm run dev

# İstemci (ayrı terminal, Flutter 3.41+)
cd app && flutter run -d chrome
```

Uygulama kodu değişince hazır build'i yenilemek için (Flutter gerekir):

```bash
npm run build:web   # → server/public (CanvasKit CDN'den geldiği için dahil değil)
```

## Backend

### Testler

```bash
npm test                 # sunucu: 46 test
cd app && flutter test   # uygulama: 42 test
```

Spec'teki "minimum test" senaryosu `server/test/scenario.test.js`
içinde birebir ve sırayla çalışıyor:

```
✔ 1. employer login → GET /candidates → 4 kişi
✔ 2. Merve + Derya seç → POST /offers
✔ 3. worker login → GET /offers?status=pending → o iki + seed
✔ 4. accept biri, reject biri
✔ 5. GET answered → 2 kayıt
✔ 6. sayfayı yenile → aynı state (sunucu yeniden açılsa bile)
```

### Uç noktalar

Base URL `http://localhost:3000/api`. Giriş dışındaki istekler
`Authorization: Bearer <token>` ister.

| İstek | Rol | Açıklama |
|---|---|---|
| `POST /auth/login` | — | `{ "role": "employer" \| "worker" }` → sabit token (`dev-employer` / `dev-worker`) |
| `GET /candidates?tab=&sort=` | işveren | `tab=perfect\|similar`, `sort=recommended\|near\|rating` |
| `POST /offers` | işveren | `{ "workerIds": [...] }` → seçilen adaylara görüşme talebi |
| `GET /offers?status=` | iş arayan | `status=pending\|answered\|expired` (answered = accepted + rejected) |
| `GET /offers/:id` | iş arayan | Talep detayı (+ şehir, şube notu) |
| `POST /offers/:id/accept` | iş arayan | İlgileniyorum |
| `POST /offers/:id/reject` | iş arayan | İlgilenmiyorum |
| `POST /dev/reset` | — | Veriyi seed'e döndürür |
| `POST /dev/expire/:id` | — | Talebin süresini hemen doldurur ("Süresi Dolan" demosu) |

Aday fotoğrafları ve firma logoları token'sız olarak `/assets/...` altında
sunuluyor.

### Cevap biçimi ve hatalar

```json
{ "ok": true,  "data": { } }
{ "ok": false, "error": { "code": "OFFER_EXISTS", "message": "…", "ids": ["w_merve"] } }
```

| Kod | Ne zaman |
|---|---|
| 400 | Doğrulama: geçersiz rol / sorgu, boş seçim, bozuk JSON |
| 401 | Token yok ya da geçersiz (`UNAUTHORIZED`), yanlış rol (`FORBIDDEN_ROLE`) |
| 404 | Bilinmeyen aday ya da talep |
| 409 | İş kuralı: adaya zaten bekleyen talep var, talep zaten yanıtlanmış, süresi dolmuş ("Teklifin süresi doldu.") |

### Örnek istekler

VS Code'da [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)
eklentisiyle [`server/requests.http`](server/requests.http): her isteğin
üstündeki **Send Request**. Token'lar login cevabından otomatik alınıyor.

curl ile:

```bash
API=http://localhost:3000/api

# İşveren: adaylar (%100 eşleşme, en yakın)
curl -s "$API/candidates?tab=perfect&sort=near" -H "Authorization: Bearer dev-employer"

# İşveren: Merve + Derya'ya talep gönder
curl -s -X POST "$API/offers" -H "Authorization: Bearer dev-employer" \
  -H "Content-Type: application/json" -d '{"workerIds":["w_merve","w_derya"]}'

# İş arayan: bekleyen talepler
curl -s "$API/offers?status=pending" -H "Authorization: Bearer dev-worker"

# İş arayan: ilgileniyorum
curl -s -X POST "$API/offers/o_garson/accept" -H "Authorization: Bearer dev-worker"
```

### Veri

- Seed: `server/data/seed.json` (case'teki seed + referans görseldeki
  "ücret beklentisi" alanları).
- Çalışma verisi: `server/data/db.json`. İlk açılışta seed'den üretilir;
  talep kabul/red gibi yazmalar sunucu yeniden başlasa da kalır.
- Talep süreleri (`USE_NOW_PLUS_21H32M`) seed'den üretilirken hesaplanır.
  `db.json` bir günden eskiyse seed talepleri "Süresi Dolan"a düşmüş olur;
  `POST /api/dev/reset` ya da dosyayı silip sunucuyu yeniden başlatmak
  başa döndürür.

### Bilinçli kararlar

- **Sekme kuralı:** `%100 Eşleşme = score >= 80` her istekte score'dan
  hesaplanıyor. Referans görselde dört aday da %100 sekmesinde görünüyor;
  brief'teki kurala uyuldu (Merve + Ferhat / Derya + Ayşe).
- **Atomik talep gönderimi:** Seçilen adaylardan biri bile 404 ya da 409'a
  takılırsa hiçbir talep yazılmaz; hata hangi id'lerin sorunlu olduğunu
  `ids` alanında döner.
- **Süre dolması:** Arka planda zamanlayıcı yok; her okuma/yazmada o anki
  saate göre `expired`'a çevriliyor. Kalan süre metni de her istekte
  `expiresAt`'ten hesaplanıyor.
- **Yanlış rol 401:** Spec böyle istiyor (`FORBIDDEN_ROLE`); HTTP
  semantiğinde doğrusu 403.
- **Tek demo iş arayan:** `dev-worker` tüm talepleri görür; işverenin
  adaylara gönderdiği talepler de burada listelenir.

## Uygulama (Flutter web)

`app/lib` üç katman: `app/` (kök, router, bağımlılıklar), `core/` (tema,
ortak widget'lar, API istemcisi, hata tipleri), `features/<modül>/`
(bloc · data · presentation · widget). Akış tek yönlü: Repository → Bloc →
View. Sunucuyla konuşan tek yer `core/services/api_service.dart`: token'ı
ekliyor, `{ ok, data }` zarfını açıyor, her hatayı tipli bir `Failure`'a
çeviriyor; ekranlar hatayı mesaja değil `code`'a göre ayırıyor.

### Bilinçli kararlar

Kaynak önceliği brief'teki gibi: referans PNG > design tokens > sayfa
spec'leri > assets.

- **Sekme içeriği:** referansta dört aday da "%100" sekmesinde; brief'teki
  `score >= 80` kuralı uygulandı (bkz. Backend → Bilinçli kararlar).
- **Aday fotoğrafları:** paketteki fotoğraflar referanstakilerle aynı
  kişiler değil (ör. `merve.png` referanstaki Ayşe). Spec'teki dosya
  eşlemesi kullanıldı; referanstan görsel kırpılmadı.
- **Sıralama:** spec 1 chip'e her basışta sıradakine geçen bir döngü
  tanımlıyor; iki ekranda da alttan açılan bir seçim paneline çevrildi
  (seçenekler görünür, doğrudan seçiliyor).
- **Referansa göre spec'ten ayrılanlar:** Ekran 1 sekme çubuğunun iç
  boşluğu / köşesi, Görüşme Talepleri başlığının sola yaslı olması, Ekran
  2'de home indicator olmaması.
- **Telefon çerçevesi:** tokens'taki gibi 390×844 dış kutu + 11 px bezel →
  iç ekran 368 px (referansta içerik 390 px genişliğinde çizilmiş); içerik
  buna göre sığdırıldı.
- **Talebe yanıt:** iyimser — kart hemen düşüyor (animasyonlu), hata olursa
  geri geliyor; süresi dolmuş / zaten yanıtlanmış talep geri konmuyor.
- **Geri sayım:** metni sunucu üretiyor; ekran açıkken liste dakikada bir
  tazeleniyor.
- **Geri / yardım butonları** hedefsiz: case'de önceki ekran ve yardım
  sayfası tanımlı değil.

## Lisans

Tüm hakları saklıdır. Kod yalnızca Vardigo işe alım sürecindeki değerlendirme
için incelenebilir ve çalıştırılabilir; ayrıntılar [LICENSE](LICENSE) dosyasında.
