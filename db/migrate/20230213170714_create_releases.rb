class CreateReleases < ActiveRecord::Migration[7.0]
  def change
    create_table :releases, id: :uuid do |t|
      t.string :title
      t.string :genre
      t.string :cover
      t.string :type
      t.string :publisher
      t.references :artist, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :releases, :title
  end
end
