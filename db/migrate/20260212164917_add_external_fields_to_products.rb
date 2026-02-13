class AddExternalFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :external_id, :string
  end
end
