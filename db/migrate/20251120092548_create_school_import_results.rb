# frozen_string_literal: true

class CreateSchoolImportResults < ActiveRecord::Migration[7.1]
  def change
    create_table :school_import_results, id: :uuid do |t|
      t.uuid :job_id, null: false
      t.uuid :user_id, null: false
      t.jsonb :results, null: false, default: {}
      t.timestamps
    end

    add_index :school_import_results, :job_id, unique: true
    add_index :school_import_results, :user_id
  end
end
