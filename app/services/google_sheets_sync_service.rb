require "google/apis/sheets_v4"
require "googleauth"
require "securerandom"

# Google Sheet ↔ Rails Product senkronizasyon servisidir.
# Sheet ana kaynak (source of truth) kabul edilir.
class GoogleSheetsSyncService

  # Google Sheet ID (ENV üzerinden güvenli şekilde okunur)
  SHEET_ID = ENV.fetch("GOOGLE_SHEET_ID")

  # Okunacak alan (A: external_id → F: error)
  RANGE = "Sheet1!A1:F1000"

  # Hata mesajlarının yazıldığı kolon
  ERROR_COL = "F"

  # Service account credential dosyası
  CREDS_PATH = Rails.root.join("config/google_service_account.json")

  # Sheet header doğrulaması için beklenen kolon isimleri
  HEADERS = %w[external_id name price stock category error]

  # Ana senkronizasyon metodu
  def sync_from_sheet

    # Loop protection:
    # Sheet'ten gelen değişikliklerin tekrar Sheet'e push edilmesini engeller
    Current.sheet_syncing = true

    # Google Sheets API client oluşturulur
    service = sheets_service

    # Sheet satırları okunur
    rows = service.get_spreadsheet_values(SHEET_ID, RANGE).values || []

    # Sheet boşsa işlem iptal edilir
    raise "Sheet boş" if rows.empty?

    # İlk satır (header) doğrulanır
    validate_headers!(rows.first)

    # Sheet'te bulunan external_id'ler burada tutulur
    sheet_ids = []

    # Header hariç tüm satırlar işlenir
    rows.drop(1).each_with_index do |row, i|

      # Sheet satır numarası (index + header)
      sheet_row = i + 2

      # external_id yoksa UUID üretilir
      external_id = row[0].presence || SecureRandom.uuid
      sheet_ids << external_id

      # Tip dönüşümleri
      price = normalize_float(row[2])
      stock = normalize_int(row[3])

      # Price veya stock geçersizse:
      # - external_id yazılır
      # - hata Sheet'e yazılır
      # - kayıt atlanır
      unless price && stock
        write_external_id(service, sheet_row, external_id) if row[0].blank?
        write_error(service, sheet_row, "Invalid price or stock")
        next
      end

      # external_id üzerinden ürün bulunur veya oluşturulur
      product = Product.find_or_initialize_by(external_id: external_id)

      # Sheet verileri Rails modeline atanır
      product.assign_attributes(
        name: row[1].to_s.strip,
        price: price,
        stock: stock,
        category: row[4].to_s.strip
      )

      if product.save
        # Yeni kayıt ise external_id Sheet'e yazılır
        write_external_id(service, sheet_row, external_id) if row[0].blank?

        # Hata kolonunu temizle
        clear_error(service, sheet_row)
      else
        # Validation hataları Sheet'e yazılır
        write_error(service, sheet_row, product.errors.full_messages.join(", "))
      end
    end

    # Sheet'te olmayan Rails kayıtları silinir
    # Böylece gerçek mirror senkronizasyon sağlanır
    Product.where.not(external_id: sheet_ids).find_each do |p|
      p.destroy
    end

  ensure
    # Her durumda loop flag kapatılır
    Current.sheet_syncing = false
  end

  private

  # Header birebir eşleşiyor mu kontrol edilir
  def validate_headers!(row)
    unless row.map(&:to_s) == HEADERS
      raise "Header yanlış. Beklenen: #{HEADERS.join(', ')}"
    end
  end

  # Virgül destekli float dönüşümü
  def normalize_float(v)
    Float(v.to_s.gsub(",", ".")) rescue nil
  end

  # Integer dönüşümü
  def normalize_int(v)
    Integer(v) rescue nil
  end

  # external_id Sheet'e yazılır
  def write_external_id(service, row, id)
    service.update_spreadsheet_value(
      SHEET_ID,
      "Sheet1!A#{row}",
      Google::Apis::SheetsV4::ValueRange.new(values: [[id]]),
      value_input_option: "RAW"
    )
  end

  # Hata mesajı Sheet'e yazılır
  def write_error(service, row, msg)
    service.update_spreadsheet_value(
      SHEET_ID,
      "Sheet1!#{ERROR_COL}#{row}",
      Google::Apis::SheetsV4::ValueRange.new(values: [[msg]]),
      value_input_option: "RAW"
    )
  end

  # Hata kolonunu temizler
  def clear_error(service, row)
    write_error(service, row, "")
  end

  # Google Service Account ile Sheets API client oluşturur
  def sheets_service
    auth = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(CREDS_PATH),
      scope: ["https://www.googleapis.com/auth/spreadsheets"]
    )

    auth.fetch_access_token!

    Google::Apis::SheetsV4::SheetsService.new.tap do |s|
      s.authorization = auth
    end
  end
end
