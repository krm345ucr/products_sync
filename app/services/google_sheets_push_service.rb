class GoogleSheetsPushService
  # Google Sheet ID (ENV üzerinden okunur)
  SHEET_ID = ENV.fetch("GOOGLE_SHEET_ID")

  # Yazılacak kolon aralığı (external_id → category)
  RANGE = "Sheet1!A2:E"

  # Google Service Account credential dosyası
  CREDS_PATH = Rails.root.join("config/google_service_account.json")

  def initialize(product)
    # Rails tarafındaki Product modeli
    @product = product
  end

  def call
    # Authorized Google Sheets client oluşturulur
    service = sheets_service

    # Ürün Sheet'te var mı diye satır aranır
    row = find_row(service)

    # Rails product verileri Google Sheet formatına dönüştürülür
    vr = Google::Apis::SheetsV4::ValueRange.new(values: [[
      @product.external_id,
      @product.name,
      @product.price,
      @product.stock,
      @product.category
    ]])

    # Eğer Sheet'te varsa UPDATE, yoksa APPEND yapılır
    row ? update_row(service, vr, row) : append_row(service, vr)

  rescue => e
    # Google API veya network hataları uygulamayı çökertmez
    Rails.logger.error("Push failed: #{e.message}")
  end

  private

  # Mevcut satırı günceller
  def update_row(service, vr, row)
    service.update_spreadsheet_value(
      SHEET_ID,
      "Sheet1!A#{row}:E#{row}",
      vr,
      value_input_option: "RAW"
    )
  end

  # Yeni satır ekler
  def append_row(service, vr)
    service.append_spreadsheet_value(
      SHEET_ID,
      RANGE,
      vr,
      value_input_option: "RAW"
    )
  end

  # Google Sheets API authentication
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

  # external_id üzerinden Sheet'teki satırı bulur
  def find_row(service)
    rows = service.get_spreadsheet_values(SHEET_ID, "Sheet1!A2:A").values || []

    rows.each_with_index do |r, i|
      # external_id eşleşirse Sheet row numarası döner
      return i + 2 if r.first == @product.external_id
    end

    nil
  end
end
