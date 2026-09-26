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

## Hızlı başlangıç

```bash
# API → http://localhost:3000/api   (Node 20+)
cd server
npm install
npm run dev

# İstemci (ayrı terminal)
cd app
flutter run -d chrome
```

Tek komutla çalıştırma (API + hazır web build) ilerleyen commit'lerde eklenecek.

## Backend

### Testler

```bash
cd server
npm test
```

40 test. Spec'teki "minimum test" senaryosu `test/scenario.test.js`
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

## Lisans

Tüm hakları saklıdır. Kod yalnızca Vardigo işe alım sürecindeki değerlendirme
için incelenebilir ve çalıştırılabilir; ayrıntılar [LICENSE](LICENSE) dosyasında.
