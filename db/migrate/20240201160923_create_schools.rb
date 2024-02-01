class CreateSchools < ActiveRecord::Migration[7.0]
  def change
    create_table :schools, id: :uuid do |t|
      t.uuid :organisation_id, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :schools, :organisation_id, unique: true
  end
end
