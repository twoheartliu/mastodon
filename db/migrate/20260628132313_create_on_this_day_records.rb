# frozen_string_literal: true

class CreateOnThisDayRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :on_this_day_records do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.date :date, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :on_this_day_records, [:account_id, :date], unique: true
    add_index :on_this_day_records, :date
  end
end
