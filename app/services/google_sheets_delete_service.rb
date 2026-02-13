class GoogleSheetsDeleteService
  # Google Sheet ID (ENV üzerinden okunur, koda gömülmez)
  SHEET_ID = ENV.fetch("GOOGLE_SHEET_ID")

  # Service account credential dosyasının yolu
  CREDS_PATH = Rails.root.join("config/google_service_account.json")

  def initialize(external_id)
    # Rails tarafındaki ürünün unique external_id'si
    @external_id = external_id
  end

  def call
    # Google Sheets API client oluşturulur
    service = sheets_service

    # Sheet'teki external_id kolonunu (A sütunu) okur
    rows = service.get_spreadsheet_values(SHEET_ID, "Sheet1!A2:A").values || []

    # Silinecek ürünün Sheet içindeki satır index'ini bulur
    index = rows.find_index do |r|
      r.first.to_s.strip == @external_id.to_s.strip
    end

    Rails.logger.warn " DELETE SEARCH #{@external_id}"
    Rails.logger.warn " FOUND ROW #{index}"

    # Eğer Sheet'te bulunamazsa hiçbir işlem yapmaz (silent fail)
    return if index.nil?

    # Google Sheets API batch_update kullanarak ilgili satırı fiziksel olarak siler
    service.batch_update_spreadsheet(
      SHEET_ID,
      Google::Apis::SheetsV4::BatchUpdateSpreadsheetRequest.new(
        requests: [
          {
            delete_dimension: {
              range: {
                sheet_id: 0,           # İlk sheet
                dimension: "ROWS",    # Satır silme işlemi
                start_index: index + 1, # Header yüzünden +1
                end_index: index + 2
              }
            }
          }
        ]
      )
    )

  rescue => e
    # Google API veya ağ hataları Rails log'una yazılır
    Rails.logger.error " SHEET DELETE FAILED: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  private

  def sheets_service
    # Google Service Account ile authentication yapılır
    auth = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(CREDS_PATH),
      scope: ["https://www.googleapis.com/auth/spreadsheets"]
    )

    auth.fetch_access_token!

    # Authorized Sheets client döndürülür
    Google::Apis::SheetsV4::SheetsService.new.tap do |s|
      s.authorization = auth
    end
  end
end
