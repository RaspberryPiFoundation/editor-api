# frozen_string_literal: true

class PublicProject
  include ActiveModel::Validations

  attr_reader :project

  delegate :identifier, :name, to: :project

  validates :identifier, format: { with: PhraseIdentifier::PATTERN, allow_blank: true }
  validates :name, presence: true

  def initialize(project)
    @project = project
  end

  def valid?
    valid = super
    project_valid = project.valid?
    errors.merge!(project.errors)
    valid && project_valid
  end

  def save!
    raise_validation_error unless valid?

    project.save!
  end

  private

  def merge_errors
    project.errors.details.each do |attribute, details_array|
      details_array.each_with_index do |details, index|
        message = project.errors[attribute][index]
        errors.add(attribute, message, **details)
      end
    end
  end
end
