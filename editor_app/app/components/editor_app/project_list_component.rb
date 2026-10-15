# frozen_string_literal: true

module EditorApp
  class ProjectListComponent < BaseComponent
    attr_reader :projects

    def initialize(projects:)
      super()
      @projects = projects
    end
  end
end
