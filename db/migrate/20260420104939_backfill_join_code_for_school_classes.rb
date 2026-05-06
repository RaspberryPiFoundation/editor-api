class BackfillJoinCodeForSchoolClasses < ActiveRecord::Migration[7.2]
  def up
    SchoolClass.find_each do |school_class|
      school_class.assign_join_code
      school_class.save!(validate: false)
    end
  end

  def down
    # No need to revert - join codes can stay
  end
end
