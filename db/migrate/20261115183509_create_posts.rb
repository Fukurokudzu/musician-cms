class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.boolean :soft_deleted, default: false, null: false
      t.string :external_id

      t.timestamps
    end

    add_index :posts, :external_id, unique: true
    add_index :posts, :soft_deleted
  end
end
