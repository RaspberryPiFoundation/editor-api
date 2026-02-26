class AddUserOriginToSchools < ActiveRecord::Migration[7.1]
  def change
    add_column :schools, :user_origin, :integer, default: 0
  end
end
