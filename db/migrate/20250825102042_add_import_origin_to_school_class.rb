class AddImportOriginToSchoolClass < ActiveRecord::Migration[7.1]
  def change
    add_column :school_classes, :import_origin, :integer, default: nil, null: true

    # The courseID is a numeric string, without a set length
    add_column :school_classes, :import_id, :string
  end
end
