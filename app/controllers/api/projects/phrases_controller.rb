# frozen_string_literal: true

module Api
  module Projects
    class PhrasesController < ApiController
      require 'phrase_identifier'

      def show
        @project = Project.find_by!(identifier: params[:id])
        @user_id = oauth_user_id
        render '/api/projects/show', formats: [:json]
      end

      def update
        @project = Project.find_by!(identifier: params[:id])

        if oauth_user_id && oauth_user_id == @project.user_id
          components = project_params[:components]

          components.each do |comp_params|
            component = Component.find(comp_params[:id])
            component.update(comp_params)
          end
          head :ok
        else
          head :unauthorized
        end
      end

      private

      def project_params
        params.require(:project).permit(:identifier, :type, components: %i[id name extension content])
      end
    end
  end
end
