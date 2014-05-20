class CreateVideoRelations < ActiveRecord::Migration
  def change
    create_table :video_relations do |t|
      t.integer :page_id, null: false
      t.integer :video_id, null: false

      t.timestamps
    end

    add_index :video_relations, :page_id, unique: false
    add_index :video_relations, [:page_id, :video_id], unique: true
  end
end
