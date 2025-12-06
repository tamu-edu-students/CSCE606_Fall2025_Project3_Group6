# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_06_020125) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "achievements", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.text "description"
    t.string "icon_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "email_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "new_follower"
    t.boolean "review_votes"
    t.boolean "followed_activity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_email_preferences_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "follower_id", null: false
    t.bigint "followed_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name"
    t.integer "tmdb_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tmdb_id"], name: "index_genres_on_tmdb_id"
  end

  create_table "list_items", force: :cascade do |t|
    t.bigint "list_id", null: false
    t.bigint "movie_id", null: false
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["list_id"], name: "index_list_items_on_list_id"
    t.index ["movie_id"], name: "index_list_items_on_movie_id"
  end

  create_table "lists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.text "description"
    t.boolean "public"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_lists_on_user_id"
  end

  create_table "log_tags", force: :cascade do |t|
    t.bigint "log_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["log_id"], name: "index_log_tags_on_log_id"
    t.index ["tag_id"], name: "index_log_tags_on_tag_id"
  end

  create_table "logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "movie_id", null: false
    t.date "watched_on"
    t.integer "rating"
    t.text "review_text"
    t.boolean "rewatch"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_logs_on_movie_id"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "movie_genres", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "genre_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_movie_genres_on_genre_id"
    t.index ["movie_id"], name: "index_movie_genres_on_movie_id"
  end

  create_table "movie_people", force: :cascade do |t|
    t.bigint "movie_id", null: false
    t.bigint "person_id", null: false
    t.string "role"
    t.string "character"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_movie_people_on_movie_id"
    t.index ["person_id"], name: "index_movie_people_on_person_id"
  end

  create_table "movies", force: :cascade do |t|
    t.integer "tmdb_id"
    t.string "title"
    t.text "overview"
    t.string "poster_path"
    t.date "release_date"
    t.integer "runtime"
    t.float "popularity"
    t.datetime "cached_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tmdb_id"], name: "index_movies_on_tmdb_id"
  end

  create_table "notification_preferences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "review_created", default: true
    t.boolean "review_voted", default: true
    t.boolean "user_followed", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notification_preferences_on_user_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "actor_id"
    t.string "notification_type"
    t.string "notifiable_type"
    t.integer "notifiable_id"
    t.boolean "read"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "body"
    t.index ["user_id", "notifiable_type", "notifiable_id"], name: "index_notifications_on_recipient_and_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "people", force: :cascade do |t|
    t.integer "tmdb_id"
    t.string "name"
    t.string "profile_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "movie_id", null: false
    t.text "body"
    t.integer "rating"
    t.boolean "reported"
    t.integer "cached_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_reviews_on_movie_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_achievements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "achievement_id", null: false
    t.datetime "earned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_user_achievements_on_achievement_id"
    t.index ["user_id"], name: "index_user_achievements_on_user_id"
  end

  create_table "user_stats", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "total_movies"
    t.integer "total_hours"
    t.integer "total_reviews"
    t.integer "total_rewatches"
    t.json "top_genres_json"
    t.json "top_actors_json"
    t.json "top_directors_json"
    t.json "heatmap_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_stats_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username"
    t.boolean "profile_public"
    t.integer "xp"
    t.boolean "banned"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "votes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "review_id", null: false
    t.integer "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_votes_on_review_id"
    t.index ["user_id"], name: "index_votes_on_user_id"
  end

  create_table "watch_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_watch_histories_on_user_id", unique: true
  end

  create_table "watch_logs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "movie_id", null: false
    t.date "watched_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "watch_history_id", null: false
    t.index ["movie_id"], name: "index_watch_logs_on_movie_id"
    t.index ["user_id", "movie_id", "watched_on"], name: "index_watch_logs_on_user_movie_watched_on"
    t.index ["user_id"], name: "index_watch_logs_on_user_id"
    t.index ["watch_history_id"], name: "index_watch_logs_on_watch_history_id"
  end

  create_table "watchlist_items", force: :cascade do |t|
    t.bigint "watchlist_id", null: false
    t.bigint "movie_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["movie_id"], name: "index_watchlist_items_on_movie_id"
    t.index ["watchlist_id", "movie_id"], name: "index_watchlist_items_on_watchlist_id_and_movie_id", unique: true
    t.index ["watchlist_id"], name: "index_watchlist_items_on_watchlist_id"
  end

  create_table "watchlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_watchlists_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "email_preferences", "users"
  add_foreign_key "follows", "users", column: "followed_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "list_items", "lists"
  add_foreign_key "list_items", "movies"
  add_foreign_key "lists", "users"
  add_foreign_key "log_tags", "logs"
  add_foreign_key "log_tags", "tags"
  add_foreign_key "logs", "movies"
  add_foreign_key "logs", "users"
  add_foreign_key "movie_genres", "genres"
  add_foreign_key "movie_genres", "movies"
  add_foreign_key "movie_people", "movies"
  add_foreign_key "movie_people", "people"
  add_foreign_key "notification_preferences", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "reviews", "movies"
  add_foreign_key "reviews", "users"
  add_foreign_key "user_achievements", "achievements"
  add_foreign_key "user_achievements", "users"
  add_foreign_key "user_stats", "users"
  add_foreign_key "votes", "reviews"
  add_foreign_key "votes", "users"
  add_foreign_key "watch_histories", "users"
  add_foreign_key "watch_logs", "movies"
  add_foreign_key "watch_logs", "users"
  add_foreign_key "watch_logs", "watch_histories"
  add_foreign_key "watchlist_items", "movies"
  add_foreign_key "watchlist_items", "watchlists"
  add_foreign_key "watchlists", "users"
end
