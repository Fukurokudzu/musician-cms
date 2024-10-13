class AddPosToTrack < ActiveRecord::Migration[7.0]
  def change
    add_column :tracks, :pos, :integer
  end
end
