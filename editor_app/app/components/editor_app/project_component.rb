# frozen_string_literal: true

module EditorApp
  # Renders the editor-ui web component, and the page-level behaviour that the
  # component asks its host for through the events in
  # editor-ui/src/events/WebComponentCustomEvents.js.
  class ProjectComponent < BaseComponent
    FEEDBACK_FORM_URL = 'https://form.raspberrypi.org/f/code-editor-feedback'
    SIDEBAR_OPTIONS = %w[projects file images settings info].freeze

    attr_reader :project, :signed_in

    delegate :auth_key, to: :EditorHydraClient

    def initialize(project:, signed_in: false)
      super()
      @project = project
      @signed_in = signed_in
    end

    def attributes
      {
        auth_key:,
        identifier: project.identifier,
        locale: I18n.locale,
        load_remix_disabled: true,
        with_projectbar: true,
        project_name_editable: true,
        with_sidebar: true,
        sidebar_options: SIDEBAR_OPTIONS.to_json,
        output_split_view: true,
        load_cache: true,
        feedback_form_url: FEEDBACK_FORM_URL,
        offline_enabled: false,
        friendly_errors_enabled: friendly_errors_enabled?
      }
    end

    def login_path
      editor_login_path(return_to: project_path(project.identifier))
    end

    private

    # The web component reads every boolean attribute as `value !== 'false'`,
    # so a disabled feature has to be spelled out rather than left off.
    def friendly_errors_enabled?
      Flipper.enabled?(:friendly_errors)
    end
  end
end
