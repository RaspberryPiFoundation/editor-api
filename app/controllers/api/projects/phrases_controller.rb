# frozen_string_literal: true

module Api
  module Projects
    class PhrasesController < ApiController
      require 'phrase_identifier'

      def show
        @project = Project.find_by!(identifier: params[:id])
        render '/api/projects/show', formats: [:json]
      end

      def update
        @project = Project.find_by!(identifier: params[:id])

        if oauth_user_id && oauth_user_id == @project.user_id
          components = project_params[:components]

          components.each do |comp_params|
            update_component(comp_params)
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

      def update_component(comp_params)
        if !comp_params[:id].nil?
          component = Component.find(comp_params[:id])
          component.update(comp_params)
        elsif !comp_params[:content].nil?
          @project.components << Component.new(comp_params)
          @project.save
        end
      end
    end
  end
end
