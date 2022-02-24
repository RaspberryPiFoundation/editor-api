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
        components = project_params[:components]

        components.each do |comp_params|
          component = Component.find(comp_params[:id])
          component.update(comp_params)
        end

        head :ok
      end

      # def remix
      #   puts '*'*50
      #   puts "DBG: #{params}"
      #   puts '*'*50
      #   old = Project.find_by!(identifier: params[:phrase_id])
      #
      #   @project = old.dup
      #   @project.identifier = PhraseIdentifier.generate
      #
      #   old.components.each do |component|
      #     @project.components << component.dup
      #   end
      #
      #   @project.save
      #
      #   render '/api/projects/show', formats: [:json]
      # end

      private

      def project_params
        params.require(:project).permit(:identifier, :type, components: %i[id name extension content])
      end
    end
  end
end
