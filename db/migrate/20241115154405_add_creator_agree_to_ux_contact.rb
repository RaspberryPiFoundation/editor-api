class AddCreatorAgreeToUxContact < ActiveRecord::Migration[7.1]
  def change
    add_column :schools, :creator_agree_to_ux_contact, :boolean, default: false
  end
end
