class AddUniqueIndexesToArtistsAndReleases < ActiveRecord::Migration[8.1]
  def change
    remove_index :artists, :title
    add_index :artists, :title, unique: true
    add_index :releases, %i[artist_id title], unique: true
  end
end
