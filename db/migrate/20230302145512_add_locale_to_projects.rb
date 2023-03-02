class AddLocaleToProjects < ActiveRecord::Migration[7.0]
  def change
    add_column :projects, :project_locale, :string
  end
end
