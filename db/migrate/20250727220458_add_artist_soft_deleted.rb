class AddArtistSoftDeleted < ActiveRecord::Migration[7.2]
  def up
    add_column :artists, :soft_deleted, :boolean, default: false, null: false
  end

def down
    remove_column :artists, :soft_deleted
  end
end
