class CreateInteractions < ActiveRecord::Migration[8.1]
  def change
    create_table :interactions do |t|
      t.string :substance_a
      t.string :substance_b
      t.string :severity
      t.text :summary

      t.timestamps
    end
  end
end
