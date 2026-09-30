# frozen_string_literal: true

module EditorApp
  # Engine route helpers and the engine's own helpers are reached through the
  # view context, so they are delegated here to keep component templates
  # readable.
  class BaseComponent < ViewComponent::Base
    delegate :home_path, :education_path, :projects_path, :project_path,
             :code_classroom_url, :projects_site_url,
             :editor_login_path, :editor_logout_path, :editor_login_authenticity_token,
             to: :helpers
  end
end
