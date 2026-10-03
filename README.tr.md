# E-Ticaret Yönetici Analitiği

> **Gelir yıllık %138 arttı, ancak tahmini kâr marjı 1,15 puan düştü. Ana neden: ürün fiyatları sabit kalırken ürün başına nakliye maliyeti %6 arttı.**

🇬🇧 [English README](README.md)

## İş problemi

Şirketin satışları, kârlılığı ve müşteri performansı nasıl gelişiyor ve marjdaki değişimin arkasında ne var? Bu, uçtan uca bir analist projesidir: ham veri, SQL modelleme, marj etken analizi, Tableau dashboard'u ve tek sayfalık yönetici özeti.

## Dashboard

![Dashboard](docs/images/dashboard_overview.png)

Tableau dashboard'u (SQL view'larının CSV çıktısından üretildi) hikâyeyi üç grafikle anlatır:

1. **Gelir ve marj trendi (Oca 2017 – Ağu 2018):** gelir istikrarlı artarken aylık marj yaklaşık %25'ten %21–22'ye düşüyor.
2. **Maliyet yapısı (Oca–Ağu 2017 vs Oca–Ağu 2018):** nakliye gelirin %16,04'ünden %17,06'sına çıkıyor, marj %22,76'dan %21,61'e düşüyor.
3. **Ürün başına nakliye:** BRL 19,32 → 20,48 (+%6), ortalama ürün fiyatı sabit (120,46 → 120,08). Marj düşüşünün ana nedeni bu.

## Veri seti

[Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): yaklaşık 100 bin sipariş, 9 tablo. İndirme adımları için `data/README.md` dosyasına bak.

**Analiz penceresi:** Ocak 2017 – Ağustos 2018 (2016 çok seyrek, Ağustos 2018 sonrası veri eksik). İptal edilen ve stokta olmayan siparişler hariç tutuldu. YoY karşılaştırması **Oca–Ağu 2018 ile Oca–Ağu 2017** arasındadır.

## Temel bulgular (Oca–Ağu 2018 vs Oca–Ağu 2017)

| Gösterge | 2017 | 2018 | Değişim |
|---|---|---|---|
| Gelir (BRL) | 3,08M | 7,34M | +%138,3 |
| Tahmini kâr (BRL) | 701K | 1,59M | +%126,3 |
| Kâr marjı | %22,76 | %21,61 | **-1,15 pp** |
| Sipariş | 22.562 | 53.530 | +%137,3 |
| AOV (BRL) | 136,55 | 137,14 | +%0,4 |
| Müşteri | 21.936 | 52.336 | +%138,6 |

1. **Büyüme hacimden geliyor.** Sipariş sayısı 2 katından fazla arttı, sepet büyüklüğü değişmedi.
2. **Marj erozyonunun ana nedeni nakliye.** Ürün başına nakliye %6,0 arttı (BRL 19,32 → 20,48), ortalama ürün fiyatı sabit kaldı (120,46 → 120,08). Nakliye gelirin %16,04'ünden %17,06'sına çıktı (+1,02 pp). Şirket nakliye maliyetinin tamamını üstleniyorsa (ana varsayımım) düşüşün yaklaşık %89'u buradan gelir. COGS payı yalnızca +0,13 pp değişti.
3. **Coğrafi kayma sorunu değil.** Marj beş bölgenin hepsinde düştü (Güneydoğu -0,8 pp, Güney -1,7, Kuzeydoğu -2,4, Orta-Batı -2,2, Kuzey -2,8). Bölge karışımı etkisi hafif pozitif (+0,13 pp).
4. **Büyüme yavaşlıyor.** Aylık YoY gelir artışı Ocak'ta %687'den Ağustos'ta %49'a düştü. Bunun büyük kısmı düşük taban etkisidir (Ocak 2017'de yalnızca 800 sipariş). 2018'de aylık sipariş 6–7 bin bandında yatay.
5. **Marj erozyonunun çoğu 2017'de yaşandı.** Aylık marj Ocak 2017'de %24,9, Ağustos 2017'de yaklaşık %21,6 idi. 2018'de %21–22 civarında dengelendi.

Tam özet: [`docs/executive_summary.md`](docs/executive_summary.md)

## Varsayımlar ve sınırlılıklar (önemli)

Olist'te **maliyet verisi yok**, bu yüzden kâr bir **tahmindir**:

`kâr = fiyat − fiyat × kategori_cogs_oranı − nakliye × şirketin_üstlendiği_pay`

- Kategori COGS oranları benim varsayımlarım (`sql/02_staging/01_cost_assumptions.sql`). Özel oranı olmayan kategoriler %65 varsayılan oranı kullanır.
- `freight_value` gerçek veridir, ancak müşteriden tahsil edilen nakliye bedelidir. Bunu şirket maliyeti saymak bir varsayımdır.
- Tüm parametreler `cost_parameters` tablosunda tutulur, senaryolar yeniden çalıştırılabilir.

**Hassasiyet analizi**

| Senaryo | Marj 2017 | Marj 2018 | Değişim |
|---|---|---|---|
| Nakliyenin %100'ü şirkette (ana senaryo) | %22,76 | %21,61 | -1,15 pp |
| Nakliyenin %50'si şirkette | %30,78 | %30,14 | -0,64 pp |

Marj seviyesi varsayımlara bağlıdır. Değişimin yönü ve ana nedeni (ürün başına nakliye) ise değişmez: iki senaryoda da düşüşün yaklaşık %80–89'u nakliyeden gelir.

## Yöntem

- **SQL (PostgreSQL):** CTE, window function'lar (`LAG`, `RANK`, `DENSE_RANK`, `NTILE`, kümülatif toplam), karmaşık JOIN'ler ve view'lar. İş kuralları staging view'larında tek yerde tanımlıdır.
- **Margin bridge:** Marj değişimi **mix etkisi** (kategori/bölge karışımı) ve **rate etkisi** (kategori/bölge içi marj değişimi) olarak ayrıştırıldı.
- **Veri kalitesi:** Yorumlar sipariş başına teke indirildi (547 siparişte birden fazla vardı), böylece gelir iki kez sayılmıyor. Müşteri tanımı `customer_unique_id` üzerinden yapıldı.
- **Ek SQL analizleri:** ürün sıralaması, bölgesel performans, RFM müşteri segmentasyonu ve teslimat-yorum ilişkisi `sql/03_analysis` klasöründe.
- **Dashboard:** Tableau. SQL view'larının CSV çıktısıyla beslenir.

## Klasör yapısı

```
sql/01_schema      tablolar, index'ler, veri kalitesi kontrolleri
sql/02_staging     maliyet varsayımları, temiz view'lar
sql/03_analysis    aylık gelir, YoY, AOV, kâr, ranking, bölge, RFM, teslimat, margin bridge, nakliye analizi
sql/04_bi_views    Tableau'ya giden view'lar
python/            load_data.py, export_views.py
docs/              yönetici özeti, görseller
```

## Nasıl çalıştırılır

```bash
brew install postgresql@16 && createdb ecommerce_analytics
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
# Kaggle CSV'lerini data/raw/ içine koy
psql -d ecommerce_analytics -f sql/01_schema/01_create_tables.sql
python python/load_data.py
psql -d ecommerce_analytics -f sql/01_schema/02_create_indexes.sql
psql -d ecommerce_analytics -f sql/02_staging/01_cost_assumptions.sql
psql -d ecommerce_analytics -f sql/02_staging/02_clean_views.sql
psql -d ecommerce_analytics -f sql/03_analysis/09_margin_driver_analysis.sql
psql -d ecommerce_analytics -f sql/04_bi_views/01_bi_views.sql
python python/export_views.py
```

