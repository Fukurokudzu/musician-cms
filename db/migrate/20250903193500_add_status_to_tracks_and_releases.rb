class AddStatusToTracksAndReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :tracks, :status, :string, null: false, default: 'draft' unless column_exists?(:tracks, :status)

    add_column :releases, :status, :string, null: false, default: 'draft' unless column_exists?(:releases, :status)
  end
end

