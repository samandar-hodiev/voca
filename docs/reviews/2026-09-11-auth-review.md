# Autentifikatsiya review hisoboti

- **Sana:** 2026-09-11
- **Qamrov:** splash'dan keyingi barcha kirish yo'llari, backend auth moduli, tezlik
  cheklovi, pochta yetkazish va mobil sessiya.

## Xulosa

Siz sanagan to'rt yo'l ishlaydi va buni dalil bilan tekshirdim. Lekin "hammasi tayyor"
deyish uchun yetarli emas edi: review ikkita jiddiy xavfsizlik nuqsoni va bitta mahsulot
bo'shlig'ini topdi. Uchalasi ham tuzatildi va testlar bilan qoplandi.

## Ishlashi tasdiqlangan yo'llar

| Yo'l | Dalil |
|---|---|
| Email bilan ro'yxatdan o'tish | Brevo orqali uch xil manzilga haqiqiy xat ketdi, jumladan begona `outlook.com` |
| Band manzilni aniqlash | `409 EMAIL_ALREADY_EXISTS` qaytadi, ilova "kirish" tugmasini taklif qiladi |
| Mavjud akkauntga kirish | E2E testi haqiqiy ilovada o'tdi |
| Parolni tiklash | Kod haqiqiy pochtaga bordi va tasdiqlandi |
| Mehmon sifatida kirish | E2E testi haqiqiy ilovada o'tdi |
| Google bilan kirish | Backend logida `/api/v1/auth/google` bitta `200` qaytargan |

## Topilgan va tuzatilgan nuqsonlar

### 1. Tezlik cheklovini chetlab o'tish mumkin edi (jiddiy)

Gin standart holatda har qanday proxyga ishonadi, ya'ni `ClientIP()` mijoz
`X-Forwarded-For` ga nima yozsa shuni qaytaradi. Tezlik cheklovi aynan shu qiymatga
tayanadi, shuning uchun sarlavhani har so'rovda almashtirgan har kim yangi chelak olardi.

Bu ADR-018 tayangan yagona himoyani bekor qilardi: band manzilni aytuvchi javobni
cheklovsiz so'rash mumkin edi.

Jonli backendga qarshi o'lchandi, chegara daqiqada 20:

| Holat | O'tdi | Bloklandi |
|---|---|---|
| Tuzatishdan oldin, soxta sarlavha bilan | 30 | 0 |
| Tuzatishdan keyin, soxta sarlavha bilan | 20 | 10 |

Tuzatish: standart holatda hech bir proxyga ishonilmaydi, `TRUSTED_PROXIES` bilan
sozlanadi. Yuk balansiri paydo bo'lganda uning manzili shu yerga yoziladi.

### 2. "Akkaunt bor" xati qabul qiluvchi bo'yicha cheklanmagan edi (yuqori)

Ro'yxatdan o'tishda band manzil kiritilganda egasiga xabar ketadi. Bu xabar kod
chiqarish yo'lini chetlab o'tgani uchun manzil bo'yicha cheklovga tushmas edi.

Oqibati ikki xil edi: istalgan ro'yxatdan o'tgan manzilga cheksiz xat yuborish mumkin
edi, va Brevo'ning kunlik 300 xatlik limiti tugab, **hammaning** ro'yxatdan o'tishi
to'xtab qolardi.

Tuzatish: bir manzilga qayta yuborish oynasi ichida, ya'ni 15 daqiqada, ko'pi bilan bitta
xabar. Ilovaga beriladigan javob o'zgarmaydi, shuning uchun cheklovni tashqaridan sezib
bo'lmaydi.

Bu nuqsonni test ushladi. Birinchi tuzatish urinishida almashtirish matni asl izohga
mos kelmay qolgan va jimgina hech narsa qilmagan edi. Endi almashtirish aniq moslikni
talab qiladi.

### 3. Parolsiz akkauntda vaqt farqi (past)

Google yoki mehmon akkauntiga parol bilan kirishga urinilganda javob darhol qaytardi,
noto'g'ri parol esa argon2 vaqtini olardi. Bu manzil boshqa usul bilan kiradigan
akkauntga tegishli ekanini oshkor qilardi.

Kod topilmagan akkaunt uchun vaqtni allaqachon tenglashtirardi, bu holat unutilgan edi.
Endi ikkalasi ham bir xil vaqt oladi.

Yon tuzatish: ma'lumotlar bazasi xatosi ham "noto'g'ri parol" deb qaytarilardi, bu esa
nosozlikni yashirardi. Endi u ichki xato sifatida qaytadi.

### 4. Chiqish tugmasi yo'q edi (mahsulot bo'shlig'i)

Chiqish use case'i yozilgan, lekin UI'da hech qayerda chaqirilmagan. Sozlamalar
sahifasiga ham hech qayerdan yo'l yo'q edi. Ya'ni kirgan odam hech qachon chiqa olmasdi.

Tuzatish: Home'da sozlamalar tugmasi, sozlamalarda "Hisobdan chiqish". Chiqish ikkala
sessiyani yopadi: Voca'nikini va Google'nikini.

## Tuzatilmagan, lekin bilish kerak bo'lgan narsalar

- **Mehmonni akkauntga aylantirish qurilmagan.** Mehmon sifatida kirgan odam keyinroq
  ro'yxatdan o'tsa, mehmon sifatidagi natijalari yangi akkauntga o'tmaydi.
- **Google akkauntlarida telefon raqam yo'q.** Email orqali ro'yxatdan o'tishda telefon
  majburiy, Google orqali esa so'ralmaydi. Bu mahsulot qarori talab qiladigan nomuvofiqlik.
- **Gmail manzilidan yuborilgan xatlar spamga tushishi mumkin.** Buni domen hal qiladi
  (ADR-017).
- **Tezlik cheklovi va xat cheklovi xotirada ishlaydi.** Bitta server uchun to'g'ri,
  ikkinchi instans paydo bo'lganda Redis'ga o'tkazish kerak.
- **`GoogleService-Info.plist` repozitoriyada yo'q.** Yangi klon uni Firebase konsolidan
  yuklashi kerak.
- **E2E testi faqat outbox rejimida ishlaydi.** Haqiqiy provayder yoqilganda kod pochtaga
  ketadi va test uni o'qiy olmaydi.
- **Apple bilan kirish** Apple Developer hisobi ochilgunicha qoldirildi.

## Tekshiruv

| Tekshiruv | Natija |
|---|---|
| `gofmt -l`, `go vet ./...` | toza |
| `go test ./...` | 16 paket o'tdi |
| `dart analyze` | toza |
| `flutter test` | 74 test o'tdi |
| Tezlik cheklovi, jonli backend | soxta sarlavha endi bloklanadi |

Yangi testlar: soxta sarlavha chelakni bo'lmasligi, xabar oynada bir marta ketishi,
cheklov oynasi, parolsiz akkaunt faqat "noto'g'ri ma'lumot" qaytarishi.
