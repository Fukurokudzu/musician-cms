class AddPlaysToTracks < ActiveRecord::Migration[7.0]
  def change
    add_column :tracks, :plays_count, :integer, default: 0, null: false
  end
end
