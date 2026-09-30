# frozen_string_literal: true

module EditorApp
  class ProjectListItemComponent < BaseComponent
    ICONS = {
      Project::Types::PYTHON => 'editor_app/project_type_python.svg',
      Project::Types::HTML => 'editor_app/project_type_html.svg',
      Project::Types::CODE_EDITOR_SCRATCH => 'editor_app/project_type_blocks.svg',
      Project::Types::SCRATCH => 'editor_app/project_type_blocks.svg'
    }.freeze

    attr_reader :project

    def initialize(project:)
      super()
      @project = project
    end

    def icon
      ICONS[project.project_type]
    end

    def type_name
      t("editor_app.project_types.#{project.project_type}")
    end

    def last_edited
      t('editor_app.projects.updated', time_ago: time_ago_in_words(project.updated_at))
    end

    def rename_dialog_id
      "rename-project-#{project.identifier}"
    end

    def delete_dialog_id
      "delete-project-#{project.identifier}"
    end
  end
end
