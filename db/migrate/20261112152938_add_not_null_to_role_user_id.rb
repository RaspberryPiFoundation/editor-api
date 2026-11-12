class AddNotNullToRoleUserId < ActiveRecord::Migration[8.1]
  def change
    change_column_null(:roles, :user_id, false)
  end
end
