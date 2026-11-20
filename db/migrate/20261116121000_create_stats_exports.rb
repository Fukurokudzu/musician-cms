class CreateStatsExports < ActiveRecord::Migration[8.1]
  def change
    create_table :stats_exports do |t|
      t.string :status, null: false, default: 'pending'
      t.string :kind, null: false
      t.string :range, null: false, default: '30'
      t.integer :progress, null: false, default: 0
      t.integer :row_count, null: false, default: 0
      t.text :error_message

      t.timestamps
    end

    add_index :stats_exports, :created_at
  end
end
