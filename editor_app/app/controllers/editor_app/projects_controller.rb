# frozen_string_literal: true

module EditorApp
  class ProjectsController < ApplicationController
    def show
      @project = ProjectLoader.new(params[:identifier], [params[:locale]]).load
      raise ActiveRecord::RecordNotFound unless @project

      authorize! :show, @project
      return redirect_to experience_cs_project_url, allow_other_host: true if @project.project_type == Project::Types::SCRATCH

      @script_url = WebComponent.script_url
    end

    private

    # Experience CS owns the Scratch editor, so its projects are handed back to it.
    def experience_cs_project_url
      "#{ENV.fetch('EXPERIENCE_CS_WEB_URL', nil)}/projects/#{@project.identifier}"
    end

    def show_footer?
      false
    end
  end
end
