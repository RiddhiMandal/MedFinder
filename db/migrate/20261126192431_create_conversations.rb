class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :title
      t.json :api_messages, null: false, default: []

      t.timestamps
    end
  end
end
