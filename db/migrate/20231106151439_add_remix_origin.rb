class AddRemixOrigin < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :remix_origin, :string
  end
end
