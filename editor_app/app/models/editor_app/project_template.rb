# frozen_string_literal: true

module EditorApp
  # The starter content a new project is created with, mirroring
  # src/utils/defaultProjects.js in editor-standalone. Only the two types the
  # React create modal offered outside a lesson are here: `code_editor_scratch`
  # was gated on `forLesson`, so the project index never offered it.
  module ProjectTemplate
    COMPONENTS = {
      Project::Types::PYTHON => [
        { name: 'main', extension: 'py', content: '', default: true }
      ],
      Project::Types::HTML => [
        { name: 'index', extension: 'html', content: '' },
        { name: 'style', extension: 'css', content: '' }
      ]
    }.freeze

    def self.types
      COMPONENTS.keys
    end

    def self.components(project_type)
      COMPONENTS[project_type]
    end
  end
end
