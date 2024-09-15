class RemoveCoverFromReleases < ActiveRecord::Migration[7.0]
  def change
    remove_column :releases, :cover, :string
  end
end
