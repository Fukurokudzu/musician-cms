class ChangeRoleToEnumInArtists < ActiveRecord::Migration[7.0]
  def change
    add_column :artists, :role_temp, :integer, default: 0
    Artist.reset_column_information
    Artist.find_each { |artist| artist.update(role_temp: Artist.roles[artist.role]) }
    remove_column :artists, :role
    rename_column :artists, :role_temp, :role
  end
end
