class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.string :topic
      t.text :body
      t.text :sources

      t.timestamps
    end
  end
end
