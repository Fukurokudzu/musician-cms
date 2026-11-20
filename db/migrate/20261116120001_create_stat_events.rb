class CreateStatEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :stat_events do |t|
      t.string :kind, null: false # 'play' or 'download'
      t.references :track, foreign_key: false
      t.references :release, foreign_key: false
      t.references :artist, foreign_key: false

      # Denormalized so history survives track/release deletion or retitle.
      t.string :track_title
      t.string :release_title
      t.string :artist_title

      t.string :country_code # ISO 3166-1 alpha-2, e.g. "RU"
      t.string :country_name
      t.string :ip_hash # HMAC of the remote IP, for unique-visitor counts

      t.datetime :created_at, null: false
    end

    add_index :stat_events, :kind
    add_index :stat_events, :created_at
    add_index :stat_events, %i[kind created_at]
    add_index :stat_events, :country_code
  end
end
