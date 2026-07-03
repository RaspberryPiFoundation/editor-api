class UpdateSchoolIndexConditions < ActiveRecord::Migration[8.1]
  def change
    remove_index :schools, :creator_id
    add_index :schools, :creator_id, unique: true, where: "rejected_at IS NULL AND archived_at IS NULL"

    remove_index :schools, :reference
    add_index :schools, :reference, unique: true, where: "rejected_at IS NULL AND archived_at IS NULL"

    remove_index :schools, :school_roll_number
    add_index :schools, :school_roll_number, unique: true, where: "rejected_at IS NULL AND archived_at IS NULL"
  end
end
