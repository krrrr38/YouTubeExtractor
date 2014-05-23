# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140523213544) do

  create_table "pages", force: true do |t|
    t.string   "url"
    t.boolean  "is_exist",     default: false
    t.datetime "extracted_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["url"], name: "index_pages_on_url", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",       default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "uid",                                 null: false
    t.string   "name"
    t.string   "password"
    t.string   "email",               default: ""
    t.string   "image_path",          default: ""
    t.string   "token",                               null: false
    t.string   "refresh_token",                       null: false
    t.datetime "expires_at"
    t.boolean  "expires"
    t.boolean  "admin",               default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

  create_table "video_relations", force: true do |t|
    t.integer  "page_id",    null: false
    t.integer  "video_id",   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "video_relations", ["page_id", "video_id"], name: "index_video_relations_on_page_id_and_video_id", unique: true, using: :btree
  add_index "video_relations", ["page_id"], name: "index_video_relations_on_page_id", using: :btree

  create_table "videos", force: true do |t|
    t.string   "title",         default: ""
    t.string   "youtube_id",                    null: false
    t.boolean  "is_embed",      default: false
    t.boolean  "can_auto_play", default: false
    t.boolean  "is_syndicate",  default: false
    t.boolean  "is_exist",      default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "videos", ["youtube_id"], name: "index_videos_on_youtube_id", unique: true, using: :btree

end
