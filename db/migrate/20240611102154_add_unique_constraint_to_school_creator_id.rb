class AddUniqueConstraintToSchoolCreatorId < ActiveRecord::Migration[7.0]
  def change
    add_index :schools, :creator_id, unique: true
  end
end
