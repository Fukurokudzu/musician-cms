class CreateArtists < ActiveRecord::Migration[7.0]
  def change
    create_table :artists do |t|
      t.string :title
      t.string :first_name
      t.string :last_name
      t.string :role

      t.timestamps
    end
    add_index :artists, :title
  end
end
