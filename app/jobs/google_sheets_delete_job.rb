#donmalarda kullanıcı hata görmez. google yavaşlarsa kullanıcı hata görebilir Rails → Sheetdelete
class GoogleSheetsDeleteJob < ApplicationJob
  queue_as :default

  def perform(external_id)
    GoogleSheetsDeleteService.new(external_id).call
  end
end
