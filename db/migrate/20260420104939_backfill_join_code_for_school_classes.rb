# frozen_string_literal: true

class BackfillJoinCodeForSchoolClasses < ActiveRecord::Migration[7.2]
  MAX_ATTEMPTS = 10

  def up
    SchoolClass.where(join_code: nil).find_each do |school_class|
      backfill_with_retries(school_class)
    end
  end

  def down
    # No need to revert - join codes can stay
  end

  private

  def backfill_with_retries(school_class)
    MAX_ATTEMPTS.times do
      school_class.join_code = nil
      school_class.assign_join_code
      next if school_class.errors[:join_code].any?

      begin
        school_class.save!(validate: false)
        return
      rescue ActiveRecord::RecordNotUnique
        school_class.errors.clear
        next
      end
    end

    raise "Could not generate a unique join_code for SchoolClass##{school_class.id} after #{MAX_ATTEMPTS} attempts"
  end
end
