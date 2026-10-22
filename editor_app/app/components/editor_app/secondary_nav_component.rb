# frozen_string_literal: true

module EditorApp
  class SecondaryNavComponent < BaseComponent
    HOME_PATH = %r{\A/[a-z]{2}(-[A-Z]{2})?/?\z}

    attr_reader :current_path, :user

    def initialize(current_path:, user: nil)
      super()
      @current_path = current_path
      @user = user
    end

    # The React nav showed itself only on the home and education pages.
    def render?
      HOME_PATH.match?(current_path)
    end

    def show_projects?
      user.present? && !user.student?
    end

    def show_school?
      user.present? && user.schools.active.any?
    end

    def show_separator?
      show_projects? || show_school?
    end

    def link_classes(path)
      classes = ['secondary-nav__link']
      classes << 'secondary-nav__link--active' if current_path.chomp('/') == path.chomp('/')
      classes.join(' ')
    end
  end
end
