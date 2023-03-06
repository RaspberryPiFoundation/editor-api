class MakeIdentifierAndLocaleUnique < ActiveRecord::Migration[7.0]
  def change
    add_index :projects, [:identifier, :project_locale], unique: true
  end
end
