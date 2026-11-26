class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.string :brand
      t.string :category
      t.string :form
      t.string :serving_size
      t.integer :price_cents
      t.boolean :in_stock, null: false, default: true
      t.text :ingredients
      t.text :description
      t.string :tags

      t.timestamps
    end
  end
end
