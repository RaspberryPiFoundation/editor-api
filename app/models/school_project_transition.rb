# frozen_string_literal: true

class SchoolProjectTransition < ApplicationRecord
  include Statesman::Adapters::ActiveRecordTransition

  belongs_to :school_project, inverse_of: :school_project_transitions

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = school_project.school_project_transitions.order(:sort_key).last
    return if last_transition.blank?

    last_transition.update!(most_recent: true)
  end
end
