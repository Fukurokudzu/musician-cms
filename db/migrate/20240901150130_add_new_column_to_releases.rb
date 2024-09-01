class AddNewColumnToReleases < ActiveRecord::Migration[7.0]
  def change
    add_column :releases, :release_date, :date
  end
end
