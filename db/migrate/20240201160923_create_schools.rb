class CreateSchools < ActiveRecord::Migration[7.0]
  def change
    create_table :schools, id: :uuid do |t|
      t.uuid :organisation_id, null: false
      t.uuid :owner_id, null: false
      t.string :name, null: false

      t.string :address_line_1, null: false
      t.string :address_line_2
      t.string :municipality, null: false
      t.string :administrative_area
      t.string :postal_code
      t.string :country_code, null: false

      t.datetime :verified_at
      t.timestamps
    end

    add_index :schools, :organisation_id, unique: true
  end
end
