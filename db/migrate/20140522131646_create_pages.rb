class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :url
      t.boolean :is_exist, default: false
      t.datetime :extracted_at

      t.timestamps
    end

    add_index :pages, :url, unique: true
  end
end
