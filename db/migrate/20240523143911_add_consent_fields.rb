class AddConsentFields < ActiveRecord::Migration[7.0]
  def change
    add_column :schools, :creator_agree_authority, :boolean
    add_column :schools, :creator_agree_terms_and_conditions, :boolean, default: false
  end
end
