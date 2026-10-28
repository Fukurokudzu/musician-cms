class AddPathToTracks < ActiveRecord::Migration[7.2]
  def change
    add_column :tracks, :path, :string
  end
end
