# frozen_string_literal: true

module Api
  module Scratch
    class ScratchController < ApiController
      before_action :authorize_user
      before_action :only_allow_schools_to_use_scratch

      def only_allow_schools_to_use_scratch
        return true if current_user.schools.any?

        raise ActiveRecord::RecordNotFound, 'Not Found'
      end

      def load_project
        @project = Project.find_by!(identifier: params[:id], project_type: Project::Types::CODE_EDITOR_SCRATCH)
      end
    end
  end
end
