# Vardigo Case

İki ekran (Eşleşen Personeller / Görüşme Talepleri) + REST API.

| Klasör | İçerik |
|---|---|
| `app/` | Flutter web istemci (390×844 telefon çerçevesi) |
| `server/` | Node + Express REST API |

## Geliştirme

```bash
# API  → http://localhost:3000/api   (Node 20+)
cd server && npm install && npm run dev

# İstemci
cd app && flutter run -d chrome
```

Kurulum, örnek istekler ve tek komutla çalıştırma adımları ilerleyen commit'lerde eklenecek.
