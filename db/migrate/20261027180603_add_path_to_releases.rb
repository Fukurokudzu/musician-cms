class AddPathToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :path, :string
  end
end
