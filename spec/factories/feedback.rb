# frozen_string_literal: true

# # frozen_string_literal: true

FactoryBot.define do
  factory :feedback do
    content { Faker::Lorem.sentence }
    user_id { teacher.id }
    school_project { create(:school_project, school: school, project: student_project) }

    transient do
      school { create(:school) }
      teacher { create(:teacher, school: school) }
      student { create(:student, school: school) }
      school_class { create(:school_class, school: school, teacher_ids: [teacher.id]) }
      class_student { create(:class_student, school_class: school_class, student_id: student.id) }
      parent_project { create(:project, user_id: teacher.id, school: school, lesson: create(:lesson, school_class: school_class, user_id: teacher.id)) }
      student_project { create(:project, parent: parent_project, user_id: student.id) }
    end
  end
end
