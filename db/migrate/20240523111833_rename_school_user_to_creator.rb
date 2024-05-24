class RenameSchoolUserToCreator < ActiveRecord::Migration[7.0]
  def change
    rename_column :schools, :user_id, :creator_id
  end
end
