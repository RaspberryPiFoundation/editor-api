# frozen_string_literal: true

module ProjectScoping
  extend ActiveSupport::Concern

  included do
    before_action :set_project_scope
  end

  private

  def set_project_scope
    only_scratch = params[:project_type] == Project::Types::SCRATCH
    Current.project_scope = Project.only_scratch(only_scratch)
  end
end
