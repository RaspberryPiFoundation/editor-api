class ChangeSchoolFields < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :rejected_at, :datetime, null: true
    remove_column :schools, :reference, :string
    add_column :schools, :organisation_id, :uuid, null: true
    add_column :schools, :user_id, :uuid, null: true
    add_column :schools, :website, :string, null: false
    add_column :schools, :urn, :integer, null: true
  end
end
