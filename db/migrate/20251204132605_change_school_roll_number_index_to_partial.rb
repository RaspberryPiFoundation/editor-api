# frozen_string_literal: true

class ChangeSchoolRollNumberIndexToPartial < ActiveRecord::Migration[7.2]
  def change
    remove_index :schools, :school_roll_number
    add_index :schools, :school_roll_number, unique: true, where: 'rejected_at IS NULL'
  end
end
