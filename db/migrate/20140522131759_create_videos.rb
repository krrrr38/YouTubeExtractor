class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.string :title, default: ''
      t.string :youtube_id, null: false
      t.boolean :is_embed, default: false
      t.boolean :can_auto_play, default: false
      t.boolean :is_syndicate, default: false
      t.boolean :is_exist, default: false

      t.timestamps
    end

    add_index :videos, :youtube_id, unique: true
  end
end
