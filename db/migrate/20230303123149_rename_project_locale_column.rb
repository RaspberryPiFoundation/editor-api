class RenameProjectLocaleColumn < ActiveRecord::Migration[7.0]
  def change
    rename_column :projects, :project_locale, :locale
  end
end
