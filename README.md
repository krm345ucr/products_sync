# Products Sync – Rails & Google Sheets Senkronizasyonu

Bu proje Ruby on Rails kullanılarak geliştirilmiş bir ürün yönetim uygulamasıdır.  
Uygulama Google Sheets ile **çift yönlü senkronizasyon** yapmaktadır.

Rails tarafında yapılan işlemler Sheet’e yansır, Sheet’te yapılan değişiklikler de Rails’e aktarılabilir.

---

## Özellikler

### Ürün Yönetimi (Rails)

Tam CRUD desteği:

- Listeleme
- Oluşturma
- Güncelleme
- Silme

Ürün alanları:

- external_id (UUID – Sheet eşleşmesi için)
- name
- price
- stock
- category

---

## Google Sheets Senkronizasyonu

### Rails → Google Sheets (Otomatik)

Rails tarafında:

- Ürün oluşturulursa → Sheet’e satır eklenir
- Ürün güncellenirse → Sheet güncellenir
- Ürün silinirse → Sheet’ten silinir

Bu işlemler **ActiveJob + Service pattern** ile arka planda çalışır.

---

### Google Sheets → Rails (Manuel)

Sheet’te yapılan değişiklikleri Rails’e almak için:

```bash
rails runner "GoogleSheetsSyncService.new.call"

--KURULUM--
1. Projeyi klonla
git clone https://github.com/krm345ucr/products_sync.git
cd products_sync

2. Gemleri yükle
bundle install

3. Ortam değişkeni oluştur

Root dizinde .env oluştur:

GOOGLE_SHEET_ID=sheet_id_buraya

4. Google Service Account

Google Cloud’da proje oluştur

Google Sheets API aktif et

Service Account oluştur

JSON credential indir

Dosyayı şuraya koy:

config/google_service_account.json


Sheet’i service account email’i ile paylaş.

5. Database
rails db:create
rails db:migrate

6. Server çalıştır
rails server


Tarayıcı:

http://localhost:3000/products

