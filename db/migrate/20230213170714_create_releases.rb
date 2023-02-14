class CreateReleases < ActiveRecord::Migration[7.0]
  def change
    create_table :releases do |t|
      t.string :title
      t.string :genre
      t.string :cover
      t.string :type
      t.string :publisher
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end
  end
end
