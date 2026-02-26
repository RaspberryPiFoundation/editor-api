# frozen_string_literal: true

json.array!(@school_members) do |school_member|
  case school_member.type
  when :owner
    json.set! :owner do
      json.partial! '/api/school_owners/school_owner', owner: school_member
    end
  when :teacher
    json.set! :teacher do
      json.partial! '/api/school_teachers/school_teacher', teacher: school_member
    end
  else
    json.set! :student do
      json.partial! '/api/school_students/school_student', student: school_member
    end
  end
end
