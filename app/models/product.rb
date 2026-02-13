class Product < ApplicationRecord
  NAME_NOT_ONLY_NUMBER = /\A\d+\z/

  before_validation :ensure_external_id
  before_validation :strip_strings

  after_commit :push_to_sheet, on: %i[create update]
  after_destroy_commit :delete_from_sheet

  validates :external_id, presence: true, uniqueness: true

  validates :name,
            presence: true,
            length: { minimum: 2 },
            format: {
              without: NAME_NOT_ONLY_NUMBER,
              message: "tamamen sayı olamaz"
            }

  validates :category,
            presence: true,
            length: { minimum: 2 },
            format: {
              without: NAME_NOT_ONLY_NUMBER,
              message: "tamamen sayı olamaz"
            }

  validates :price,
            numericality: { greater_than_or_equal_to: 0 }

  validates :stock,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  private

  # Sheet ile ilişkilendirme için UUID üretir
  def ensure_external_id
    self.external_id ||= SecureRandom.uuid
  end

  # Kullanıcı boşluk hatalarını engellemek için
  def strip_strings
    self.name = name.to_s.strip.presence
    self.category = category.to_s.strip.presence
  end

  # Rails tarafındaki değişiklikleri Sheet'e yollar
  def push_to_sheet
    return if Current.sheet_syncing
    GoogleSheetsPushJob.perform_later(id)
  end

  # Rails'te silinen ürünü Sheet'ten de siler
  def delete_from_sheet
    GoogleSheetsDeleteJob.perform_later(external_id)
  end
end
