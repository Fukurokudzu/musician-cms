class AddDescriptionToArtist < ActiveRecord::Migration[7.0]
  def change
    add_column :artists, :description, :text
  end
end
