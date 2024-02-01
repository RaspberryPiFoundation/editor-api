class CreateSchoolClasses < ActiveRecord::Migration[7.0]
  def change
    create_table :school_classes, id: :uuid do |t|
      t.belongs_to :school, null: false
      t.uuid :teacher_id, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :school_classes, %i[school_id teacher_id]
  end
end
