class AddUniqueIndexToProductsExternalId < ActiveRecord::Migration[8.1]
  def change
    add_index :products, :external_id, unique: true
    
  end
end
