# Loyihaning to'liq ko'rigi

- **Sana:** 2026-09-13
- **Qamrov:** ovoz tahlilining to'g'riligi (jonli Azure xizmatiga qarshi o'lchandi),
  backend va mobil modullarning haqiqiy holati, admin panel, hamda rus tilini
  qo'shish masalasi.

## Xulosa

Talaffuzni baholash zanjiri uchidan-uchiga ishlaydi va buni telefondan kelgan haqiqiy
so'rovlar tasdiqladi. Ammo ko'rik bitta **foydalanuvchi bugun sezadigan nuqsonni** topdi:
etalon so'z o'rniga butunlay boshqa so'z aytilsa, ilova "ovoz eshitilmadi" deydi. Bu
chalg'ituvchi — odam aniq gapirdi, shunchaki boshqa so'zni aytdi.

Bundan tashqari uchta jiddiy mahsulot bo'shlig'i bor: bazada so'zlar yo'q, foydalanish
chegarasi yo'q, va saqlanayotgan urinishlar hech qayerda ko'rsatilmaydi.

## 1. Ovoz tahlili to'g'ri ishlayaptimi

Bir xil etalon (`think`), uch xil aytilish. Har biri jonli Azure xizmatiga yuborildi.

| Etalon | Aytilgan | Natija | Baho |
|---|---|---|---|
| think | think | `97` ball; θ=100 ɪ=93 ŋ=100 k=31 | to'g'ri |
| think | sink | `94` ball; θ=78; "xato yo'q" | zaif |
| think | world | **"Ovoz eshitilmadi"** | nuqson |

### 1.1 Nuqson: boshqa so'z aytilganda

Azure "sukunat" va "boshqa so'z" uchun **deyarli bir xil** javob qaytaradi:

| Maydon | Sukunat | "world" (etalon: think) |
|---|---|---|
| RecognitionStatus | Success | Success |
| DisplayText | `"."` | `"."` |
| Ballar | 0 / 0 / 0 | 0 / 0 / 0 |
| ErrorType | Omission | Omission |
| Phonemes | `[]` | `[]` |
| SNR | 0.0 | 0.0 |

Farqlovchi belgi yo'q. Shuning uchun `mapper.go` dagi "sukunat" tekshiruvi ikkalasini
bir xil deb biladi va xizmat `NO_SPEECH_DETECTED` qaytaradi.

### 1.2 Yechim — o'lchov bilan isbotlangan

Etalon matnsiz ikkinchi tanish so'rovi uchala holatni ajratadi:

| Audio | Etalon bilan | Etalonsiz |
|---|---|---|
| sukunat | `"."` | `""` |
| world | `"."` | `"World."` |
| think | `"Think."` | `"Think."` |

Taklif: birinchi so'rov bo'sh signal qaytarsagina ikkinchi, etalonsiz so'rov yuborilsin.
Matn qaytsa — *"Siz «world» dedingiz, so'z esa «think»"*. Bo'sh qaytsa — *"Ovoz
eshitilmadi"*. Qo'shimcha xarajat faqat xato holatlarda bo'lgani uchun sezilarsiz.

### 1.3 Ikkinchi kamchilik: noto'g'ri so'z ham yuqori ball olishi

Etalon matn berilganda Azure ovozni kutilgan tovushlarga **majburan moslashtiradi**. U
"to'g'ri so'zni aytdingizmi?" degan savolga emas, "kutilgan tovushlar qanchalik chiqdi?"
degan savolga javob beradi. Shu sababli `sink` ham 94 ball oldi; faqat θ 100 dan 78 ga
tushdi, bu esa bizning 60 lik chegaramizdan yuqori, ya'ni hech qanday maslahat berilmadi.

Xulosa: **so'zning to'g'riligini ball emas, etalonsiz tanish tekshirishi kerak.**

> Sinovlarda `say` buyrug'ining sintez ovozi ishlatilgan. Tirik odamning talaffuzi
> boshqacha ball beradi; masalan to'g'ri aytilgan `think` da oxirgi `k` 31 ball oldi,
> chunki sintez ovozda so'z oxiri kesilgan. So'z chekkasidagi fonemalar shovqinli —
> bitta past fonema uchun darrov maslahat bermaslik kerak.

## 2. Loyihaning holati (ARCHITECTURE.md 37-bo'limiga nisbatan)

| # | Bosqich | Holat |
|---|---|---|
| 0–2 | Skelet, backend asosi, migratsiyalar | tayyor |
| 3 | `auth` + `user` | auth tayyor (2456 qator); `user` moduli qolip, profil auth ichida |
| 4 | `word` moduli + kontent | **yo'q** (59 qator qolip, jadval yo'q) |
| 5 | Mobil yadro | tayyor |
| 6 | Mobil auth + home | auth tayyor; home soxta ma'lumotda |
| 7 | `practice` moduli | qolip (74 qator); mobil soxta ma'lumotda |
| 8 | `pronunciation` moduli | tayyor (1326 qator + Azure adapteri) |
| 9 | Mobil talaffuz oqimi | tayyor |
| 10 | `progress` | qolip (94 qator) |
| 11 | `subscription` / limit | qolip (110 qator) |
| 12 | `notification` | qolip |
| 13 | Zaif tovushlar ekrani | boshlanmagan |
| 14–16 | Mustahkamlash, do'kon, ishga tushirish | boshlanmagan |

**Raqamlar:** mobil 236 fayldan 159 tasi haqiqiy (77 qolip); backend 126 fayldan 57 tasi
haqiqiy (69 qolip). Serverda uchta yo'l guruhi tirik: `auth`, `pronunciation`, `devhook`,
qo'shimcha `/config`. Admin panelda faqat "Foundation" sahifasi — mahsulot ekranlari yo'q.

## 3. Topilgan kamchiliklar

| # | Kamchilik | Daraja |
|---|---|---|
| 1 | Boshqa so'z aytilsa "ovoz eshitilmadi" deydi (1.1-bo'lim) | yuqori |
| 2 | Foydalanish chegarasi yo'q — bitta hisob oylik bepul kvotani tugatishi mumkin; yo'lda cheklovchi ochiq `nil` | yuqori |
| 3 | Bazada so'zlar yo'q — mashq so'zlari Flutter ichida qotirilgan oltita so'z | yuqori |
| 4 | Urinishlar bazaga yozilyapti, lekin Home va Progress to'qima raqam ko'rsatadi | o'rta-yuqori |
| 5 | Maslahat kamdan-kam chiqadi: fonema maslahati faqat 60 dan past so'z ichida | o'rta |
| 6 | `Idempotency-Key` yo'q — ikki marta yuborilsa kvota ikki marta yechiladi | o'rta |
| 7 | Muvaffaqiyatsiz urinish `status=failed` bilan saqlanmaydi | past |
| 8 | `pronunciation` xizmati va handleri uchun test yo'q | past |
| 9 | Azure kaliti `.env` da — dev uchun to'g'ri, ishlab chiqarishda maxfiy saqlash kerak | keyinroq |

## 4. Rus tili

Bu uchta har xil savol:

**Interfeys tili sifatida — allaqachon bor.** `uz`, `en`, `ru` uchala tarjima fayli to'liq.
Rus tilida gapiruvchi foydalanuvchi ingliz tilini o'rgansa, ilova u bilan rus tilida
gaplashadi. Qo'shimcha ish talab qilinmaydi.

**Rus talaffuzini baholash — mumkin, ammo tavsiya qilinmaydi.** O'lchandi: Azure `ru-RU`
ni baholaydi (`мир` → 100 ball), lekin fonemalar **bo'sh satr** bo'lib qaytadi:

| Alifbo | Ball | Fonemalar |
|---|---|---|
| IPA | 100 | `['', '', '']` |
| SAPI | 100 | `['', '', '']` |

Ya'ni rus tili uchun tovush darajasidagi tahlil ishlamaydi. Voca'ning asosiy ustunligi
esa aynan "sizning θ tovushingiz zaif" deya olishi; rus tilida undan quruq raqam qoladi.

**Xulosa:** rus tili interfeysda qolsin, rus talaffuzini baholash qurilmasin. Bozor
bitta — rus yoki o'zbek tilida gapiradigan, ingliz tilini o'rganuvchilar — va u
allaqachon qamrab olingan. Kelajakda kerak bo'lsa o'zgarish kichik: baholanadigan til
bitta joyda qotirilgan (`recording_controller.dart`).

## 5. Keyingi qadamlar

1. Noto'g'ri so'z nuqsonini tuzatish (yechim isbotlangan).
2. Foydalanish chegarasi — kuniga N urinish; bepul kvotani himoya qiladi.
3. So'zlar bazasi: migratsiya, `word` moduli, kontent, mobil ulash.
4. Progress'ni haqiqiy ma'lumotga o'tkazish — `GET /pronunciation/attempts` bor, mobil
   uni chaqirmaydi.
5. Maslahat chegaralarini sozlash.
6. Zaif tovushlar ekrani — ma'lumot 8-bosqichdan beri to'planyapti.
