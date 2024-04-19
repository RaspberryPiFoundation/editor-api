class ChangeSchoolFields < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :rejected_at, :datetime, null: true
    add_column :schools, :organisation_id, :uuid, null: true
    add_column :schools, :user_id, :uuid, null: true
    add_column :schools, :website, :string, null: false
  end
end
