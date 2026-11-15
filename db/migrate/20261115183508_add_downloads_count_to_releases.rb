class AddDownloadsCountToReleases < ActiveRecord::Migration[8.1]
  def change
    add_column :releases, :downloads_count, :integer, default: 0, null: false
  end
end
