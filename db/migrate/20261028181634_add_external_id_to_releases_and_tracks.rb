class AddExternalIdToReleasesAndTracks < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    add_column :releases, :external_id, :uuid, default: 'gen_random_uuid()', null: false
    add_index :releases, :external_id, unique: true

    add_column :tracks, :external_id, :uuid, default: 'gen_random_uuid()', null: false
    add_index :tracks, :external_id, unique: true
  end
end
