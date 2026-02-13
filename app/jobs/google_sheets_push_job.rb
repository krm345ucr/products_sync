# Google Sheets güncellemesini background'da çalıştırır.
# Böylece Google API yavaşlarsa kullanıcı arayüzü donmaz.

class GoogleSheetsPushJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product

    GoogleSheetsPushService.new(product).call
  end
end
