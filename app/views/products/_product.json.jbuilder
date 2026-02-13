json.extract! product, :id, :name, :price, :stock, :category, :sheet_row_id, :created_at, :updated_at
json.url product_url(product, format: :json)
