# frozen_string_literal: true

class StudentHelpers
  # Ensure that nil values are empty strings, else Profile will swallow validations
  def self.normalise_nil_values_to_empty_strings(students)
    students.map do |student|
      student.transform_values { |value| value.nil? ? '' : value }
    end
  end

  def self.decrypt_students(students)
    students.deep_dup.each do |student|
      student[:password] = DecryptionHelpers.decrypt_password(student[:password]) if student[:password].present?
    end
  end
end
