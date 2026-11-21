class RemoveLegacyStatCounters < ActiveRecord::Migration[8.1]
  # stat_events is now the only source of statistics. The old integer counters
  # are deliberately dropped without being backfilled: history before event
  # tracking is not needed.
  def change
    remove_column :tracks, :plays_count, :integer, default: 0, null: false
    remove_column :releases, :plays_count, :integer, default: 0, null: false
    remove_column :releases, :downloads_count, :integer, default: 0, null: false
    remove_column :artists, :plays_count, :integer, default: 0, null: false
  end
end
