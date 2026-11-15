class ChangeRoleToEnumInArtists < ActiveRecord::Migration[7.0]
  def change
    add_column :artists, :role_temp, :integer, default: 0
    Artist.reset_column_information
    Artist.find_each { |artist| artist.update(role_temp: Artist.roles[artist.role]) }
    # Historical migration: rolling this back was never intended — keep the
    # column definition frozen in place instead of adding an artificial revert.
    remove_column :artists, :role # rubocop:disable Rails/ReversibleMigration
    rename_column :artists, :role_temp, :role
  end
end
