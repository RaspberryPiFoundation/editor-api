# frozen_string_literal: true

class EventTracker
  class << self
    def track!(name:, user_id:, properties: {})
      Event.create!(
        name:,
        user_id:,
        properties: properties.compact,
        time: Time.current
      )
    end

    def track_project_event!(name:, user_id:, project:, user_role: nil, student_id: nil)
      properties = project_event_properties(project)
      return if properties.blank?

      role = user_role || user_role_for(user_id:, school_id: properties[:school_id])
      properties[:user_role] = role if role.present?
      properties[:student_id] = student_id || student_id_for(project:, user_role: role)

      track!(name:, user_id:, properties:)
    end

    def project_event_properties(project)
      return if project.blank?

      lesson = lesson_for(project)
      properties = {
        school_id: school_id_for(project, lesson),
        class_id: lesson&.school_class_id,
        lesson_id: lesson&.id,
        project_type: project_type_for(project)
      }.compact

      required_project_properties?(properties) ? properties : nil
    end

    private

    def required_project_properties?(properties)
      %i[school_id class_id lesson_id project_type].all? { |key| properties[key].present? }
    end

    def user_role_for(user_id:, school_id:)
      return if user_id.blank? || school_id.blank?

      Role.student.exists?(user_id:, school_id:) ? 'student' : 'educator'
    end

    def student_id_for(project:, user_role:)
      return unless educator_project_interaction?(project:, user_role:)

      student_id = project.user_id
      return if student_id.blank?

      lesson = lesson_for(project)
      student_id if ClassStudent.exists?(school_class_id: lesson.school_class_id, student_id:)
    end

    def lesson_for(project)
      project.lesson || project.parent&.lesson
    end

    def school_id_for(project, lesson)
      project.school_id || project.parent&.school_id || lesson&.school_id
    end

    def project_type_for(project)
      project.project_type || project.parent&.project_type
    end

    def educator_project_interaction?(project:, user_role:)
      return false unless user_role == 'educator'

      lesson_for(project)&.school_class_id.present?
    end
  end
end
