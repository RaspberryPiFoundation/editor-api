# frozen_string_literal: true

json.array!(@school_members) do |school_member|
  if school_member.respond_to?(:email) && school_member.email.present?
    json.set! :teacher do
      json.partial! '/api/school_teachers/school_teacher', teacher: school_member
    end
  else
    json.set! :student do
      json.partial! '/api/school_students/school_student', student: school_member
    end
  end
end
