# -*- coding: utf-8 -*-
class DeviseCreateUsers < ActiveRecord::Migration
  def change
    create_table(:users) do |t|

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ##Omniauthable with google_oauth2
      t.string    :uid,           null: false
      t.string    :name
      t.string    :password
      t.string    :email,         default: ""
      t.string    :image_path,    default: ""
      t.string    :token,         null: false
      t.string    :refresh_token, null: false
      t.timestamp :expires_at
      t.boolean   :expires

      t.boolean   :admin,         default: false

      t.timestamps
    end

    add_index :users, :uid, unique: true
  end
end
