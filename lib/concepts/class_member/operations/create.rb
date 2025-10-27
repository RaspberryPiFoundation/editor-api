# frozen_string_literal: true

module ClassMember
  class Create
    class << self
      def call(school_class:, students: [], teachers: [])
        response = OperationResponse.new
        response[:class_members] = []
        response[:errors] = {}
        raise ArgumentError, 'No valid school members provided' if students.blank? && teachers.blank?

        create_class_teachers(school_class:, teachers:, response:)
        create_class_students(school_class:, students:, response:)
        response
      rescue StandardError => e
        Sentry.capture_exception(e)
        response[:error] = "Error creating class members: #{e.message}"
        response
      end

      private

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

      def handle_class_teacher_error(exception, class_teacher, teacher, response)
        Sentry.capture_exception(exception) unless exception.is_a?(ActiveRecord::RecordInvalid)
        errors = class_teacher.errors.full_messages.join(',')
        response[:error] ||= "Error creating one or more class members - see 'errors' key for details"
        response[:errors][teacher.id] = "Error creating class member for teacher_id #{teacher.id}: #{errors}"
      end

      def handle_class_student_error(exception, class_student, student, response)
        Sentry.capture_exception(exception) unless exception.is_a?(ActiveRecord::RecordInvalid)
        errors = class_student.errors.full_messages.join(',')
        response[:error] ||= "Error creating one or more class members - see 'errors' key for details"
        response[:errors][student.id] = "Error creating class member for student_id #{student.id}: #{errors}"
      end
    end
  end
end
