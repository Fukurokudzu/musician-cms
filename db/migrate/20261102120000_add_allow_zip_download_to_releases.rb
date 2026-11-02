class AddAllowZipDownloadToReleases < ActiveRecord::Migration[7.2]
  def change
    add_column :releases, :allow_zip_download, :boolean, default: false, null: false
  end
end
