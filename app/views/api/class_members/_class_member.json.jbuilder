# frozen_string_literal: true

json.call(
  class_member,
  :id,
  :school_class_id,
  :created_at,
  :updated_at
)

if class_member.respond_to?(:student)
  json.student_id(class_member.student_id)
  json.set! :student do
    json.partial! '/api/school_students/school_student', student: class_member.student
  end
elsif class_member.respond_to?(:teacher)
  json.teacher_id(class_member.teacher_id)
  if @school_owner_ids.include?(class_member.teacher_id)
    json.set! :owner do
      json.partial! '/api/school_owners/school_owner', owner: class_member.teacher
    end
  else
    json.set! :teacher do
      json.partial! '/api/school_teachers/school_teacher', teacher: class_member.teacher
    end
  end
end
