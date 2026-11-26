class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role
      t.text :body
      t.json :trace, null: false, default: []
      t.string :status, null: false, default: "done"

      t.timestamps
    end
  end
end
