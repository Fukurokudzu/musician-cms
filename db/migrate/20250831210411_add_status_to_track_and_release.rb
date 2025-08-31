class AddStatusToTrackAndRelease < ActiveRecord::Migration[7.2]
  def change
    add_column :tracks, :status, :string, default: 'draft'
    add_column :releases, :status, :string, default: 'draft'
  end
end