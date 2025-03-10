class AssignCodeToExistingClasses < ActiveRecord::Migration[7.1]
  def up
    SchoolClass.find_each do |school_class|
      school_class.assign_class_code
      school_class.save!
    end
  end

  def down
    SchoolClass.update_all(code: nil)
  end
end
