# frozen_string_literal: true

class StudentHelpers
  # Ensure that nil values are empty strings, else Profile will swallow validations
  def self.normalise_nil_values_to_empty_strings(students)
    students.map do |student|
      student.transform_values { |value| value.nil? ? '' : value }
    end
  end
end
