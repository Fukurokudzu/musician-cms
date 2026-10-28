class AddPathToArtists < ActiveRecord::Migration[7.2]
  def change
    add_column :artists, :path, :string
  end
end
