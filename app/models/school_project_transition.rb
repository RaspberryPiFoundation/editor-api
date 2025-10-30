# frozen_string_literal: true

class SchoolProjectTransition < ApplicationRecord
  include Statesman::Adapters::ActiveRecordTransition

  # If your transition table doesn't have the default `updated_at` timestamp column,
  # you'll need to configure the `updated_timestamp_column` option, setting it to
  # another column name (e.g. `:updated_on`) or `nil`.
  #
  # self.updated_timestamp_column = :updated_on
  # self.updated_timestamp_column = nil

  belongs_to :school_project, inverse_of: :school_project_transitions

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = school_project.school_project_transitions.order(:sort_key).last
    return if last_transition.blank?

    last_transition.set_most_recent!
  end

  def set_most_recent!
    self.most_recent = true
    save!
  end
end
