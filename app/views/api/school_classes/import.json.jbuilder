# frozen_string_literal: true

school_class, teachers = @school_class_with_teachers

json.school_class do
  json.call(
    school_class,
    :id,
    :description,
    :school_id,
    :name,
    :code,
    :created_at,
    :updated_at,
    :import_origin,
    :import_id
  )

  json.teachers(teachers) do |teacher|
    json.partial! '/api/school_teachers/school_teacher', teacher:, include_email: false
  end
end

if @school_students.any?
  json.students(@school_students) do |student_item|
    json.partial! '/api/school_students/school_student', student: student_item[:student]

    # Add the metadata
    json.success student_item[:success]
    json.error student_item[:error]
    json.created student_item[:created]
  end
elsif @school_students_errors.present?
  # This is the validation error case
  json.students do
    json.errors @school_students_errors
  end
end

if @class_members.any?
  json.class_members(@class_members) do |class_member|
    if class_member.is_a?(Hash) && class_member.key?(:success) && !class_member[:success]
      # Add errors to the response
      json.merge! class_member
    else
      json.partial! '/api/class_members/class_member', class_member: class_member
      json.success true
      json.error nil
    end
  end
end
