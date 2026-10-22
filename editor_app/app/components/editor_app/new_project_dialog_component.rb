# frozen_string_literal: true

module EditorApp
  class NewProjectDialogComponent < BaseComponent
    DIALOG_ID = 'new-project'

    delegate :types, to: :'EditorApp::ProjectTemplate'

    def icon(project_type)
      ProjectListItemComponent::ICONS.fetch(project_type)
    end

    def type_name(project_type)
      t("editor_app.project_types.#{project_type}")
    end

    def type_description(project_type)
      t("editor_app.projects.new_dialog.#{project_type}_description")
    end
  end
end
