# frozen_string_literal: true

json.array!(@class_members) do |class_member|
  if class_member.respond_to?(:student_id)
    json.partial! 'class_member', class_member:
  elsif @school_owner_ids.include?(class_member.id)
    json.set! :owner do
      json.partial! '/api/school_owners/school_owner', owner: class_member
    end
  else
    json.set! :teacher do
      json.partial! '/api/school_teachers/school_teacher', teacher: class_member
    end
  end
end
