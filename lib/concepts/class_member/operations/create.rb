# frozen_string_literal: true

module ClassMember
  class Create
    class << self
      def call(school_class:, user_ids:, token:)
        response = OperationResponse.new
        response[:class_members] = []
        response[:errors] = {}
        raise ArgumentError, 'No valid users provided' if user_ids.blank?

        students = find_students(school: school_class.school, user_ids:, token:)
        create_class_students(school_class:, students:, response:)

        teachers = find_teachers(school: school_class.school, user_ids:)
        create_class_teachers(school_class:, teachers:, response:)

        invalid_user_ids = user_ids - students.map(&:id) - teachers.map(&:id)
        fail_operation = invalid_user_ids == user_ids
        invalid_user_ids.each { |user_id| handle_class_member_error(user_id, school_class.school, response, fail_operation) }

        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating class members: #{e.message}"
        response
      end

      private

      def find_students(school:, user_ids:, token:)
        student_ids = Role.where(user_id: user_ids, school:, role: 'student').pluck(:user_id)
        SchoolStudent::List.call(school:, student_ids:, token:).fetch(:school_students, [])
      end

      def find_teachers(school:, user_ids:)
        teacher_ids = Role.where(user_id: user_ids, school:, role: 'teacher').pluck(:user_id)
        SchoolTeacher::List.call(school:, teacher_ids:).fetch(:school_teachers, [])
      end

      def create_class_students(school_class:, students:, response:)
        students.each do |student|
          class_student = school_class.students.build({ student_id: student.id })
          class_student.student = student
          class_student.save!
          response[:class_members] << class_student
        rescue StandardError => e
          handle_class_student_error(e, class_student, student, response)
          response
        end
      end

      def create_class_teachers(school_class:, teachers:, response:)
        teachers.each do |teacher|
          class_teacher = school_class.teachers.build({ teacher_id: teacher.id })
          class_teacher.teacher = teacher
          class_teacher.save!
          response[:class_members] << class_teacher
        rescue StandardError => e
          handle_class_teacher_error(e, class_teacher, teacher, response)
          response
        end
      end

      def handle_class_student_error(exception, class_member, student, response)
        Sentry.capture_exception(exception)
        errors = class_member.errors.full_messages.join(',')
        response[:errors][student.id] = "Error creating class member for student #{student.id}: #{errors}"
      end

      def handle_class_teacher_error(exception, class_member, teacher, response)
        Sentry.capture_exception(exception)
        errors = class_member.errors.full_messages.join(',')
        response[:errors][teacher.id] = "Error creating class member for teacher #{teacher.id}: #{errors}"
      end

      def handle_class_member_error(user_id, school, response, fail_operation)
        response[:errors][user_id] = "Error creating class member for user #{user_id}: User '#{user_id}' does not have the 'school-teacher' or 'school-student' role for organisation '#{school.id}'"
        response.failure! if fail_operation
      end
    end
  end
end
