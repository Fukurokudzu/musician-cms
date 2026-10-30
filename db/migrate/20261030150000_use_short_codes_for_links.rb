class UseShortCodesForLinks < ActiveRecord::Migration[7.2]
  MODELS = { artists: 'Artist', releases: 'Release', tracks: 'Track' }.freeze

  def up
    add_column :artists, :external_id, :string
    add_index :artists, :external_id, unique: true

    %i[releases tracks].each do |table|
      remove_column table, :external_id
      add_column table, :external_id, :string
      add_index table, :external_id, unique: true
    end

    MODELS.each_value do |class_name|
      model = Class.const_get(class_name)
      model.reset_column_information
      model.find_each { |record| record.update_column(:external_id, generate_code(model)) }
    end
  end

  def down
    remove_column :artists, :external_id

    %i[releases tracks].each do |table|
      remove_column table, :external_id
      add_column table, :external_id, :uuid, default: -> { 'gen_random_uuid()' }, null: false
      add_index table, :external_id, unique: true
    end
  end

  private

  def generate_code(model)
    loop do
      code = SecureRandom.alphanumeric(8)
      break code unless model.exists?(external_id: code)
    end
  end
end
