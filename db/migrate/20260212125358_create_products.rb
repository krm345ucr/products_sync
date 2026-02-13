class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.integer :stock
      t.string :category
      t.string :sheet_row_id

      t.timestamps
    end
  end
end
