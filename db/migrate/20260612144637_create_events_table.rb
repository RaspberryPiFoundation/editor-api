class CreateEventsTable < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: :uuid do |t|
      t.uuid :user_id
      t.string :name, null: false
      t.jsonb :properties
      t.datetime :time, null: false
    end
  end
end
