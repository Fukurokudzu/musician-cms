class CreateTracks < ActiveRecord::Migration[7.0]
  def change
    create_table :tracks, id: :uuid do |t|
      t.string :title
      t.references :release, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
    add_index :tracks, :title
  end
end
