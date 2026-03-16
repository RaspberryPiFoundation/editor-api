# frozen_string_literal: true

module RemixSelection
  extend ActiveSupport::Concern

  def remix_for_user(project, user, include_feedback: false)
    return nil if user.nil?

    query = Project.where(remixed_from_id: project.id, user_id: user.id)
                   .order(created_at: :asc)
                   .accessible_by(current_ability)

    query = query.includes(school_project: :feedback) if include_feedback

    query.first
  end
end
