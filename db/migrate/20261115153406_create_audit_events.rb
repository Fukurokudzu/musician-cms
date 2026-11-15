class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.string :action, null: false
      t.string :actor
      t.string :target_type
      t.string :target_id
      t.string :target_label
      t.jsonb :metadata, null: false, default: {}
      t.string :ip_address
      t.string :user_agent

      t.datetime :created_at, null: false
    end

    add_index :audit_events, :action
    add_index :audit_events, :created_at
  end
end
