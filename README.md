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
### Service Pattern Kullanımı

Google Sheets entegrasyonu controller veya model içine yazılmamıştır.

Bunun yerine ayrı servis sınıfları oluşturulmuştur:

GoogleSheetsPushService

GoogleSheetsDeleteService

GoogleSheetsSyncService

Amaç:

Controller’ların sade kalması

Business logic’in izole edilmesi

Kodun test edilebilir ve sürdürülebilir olması

## Background Job Kullanımı

Google API çağrıları zaman alabileceği için işlemler ActiveJob üzerinden arka planda çalıştırılmaktadır.

Bu sayede:

Kullanıcı arayüzü bloklanmaz

Google tarafındaki gecikmeler Rails request lifecycle’ını etkilemez

## Idempotent Senkronizasyon

Her ürün unique bir external_id ile eşleştirilir.

Bu sayede:

Aynı senkronizasyon birden fazla çalıştırılsa bile duplicate kayıt oluşmaz

Güncellemeler mevcut satırı overwrite eder

Veri tutarlılığı korunur

Sync işlemi tekrar tekrar çalıştırıldığında aynı sonucu üretir.

## Transaction Kullanılmamasının Nedeni

Google Sheets harici bir sistem olduğu için ActiveRecord transaction kapsamına alınmamıştır.

Rails tarafındaki commit tamamlandıktan sonra Sheet senkronizasyonu yapılır.

Bu bilinçli bir mimari tercihtir.

## Validasyon ve Hata Yönetimi

Rails modelinde temel validasyonlar mevcuttur:

name ve category boş olamaz

tamamen sayısal olamaz

price negatif olamaz

stock integer olmalıdır

Geçersiz kayıtlar veritabanına yazılmaz.

Sheet senkronizasyon hataları Rails loglarına düşer.

## Güvenlik

Hassas dosyalar gitignore kapsamındadır:

.env

config/google_service_account.json

Repository içinde credential bulunmaz.

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

