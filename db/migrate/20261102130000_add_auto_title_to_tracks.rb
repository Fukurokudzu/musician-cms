class AddAutoTitleToTracks < ActiveRecord::Migration[7.2]
  def change
    add_column :tracks, :auto_title, :string
  end
end
