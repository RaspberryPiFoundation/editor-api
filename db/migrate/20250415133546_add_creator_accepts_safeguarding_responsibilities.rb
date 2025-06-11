class AddCreatorAcceptsSafeguardingResponsibilities < ActiveRecord::Migration[7.1]
  def change
    add_column :schools, :creator_agree_responsible_safeguarding, :boolean, default: true
  end
end
