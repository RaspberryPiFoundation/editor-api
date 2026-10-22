# frozen_string_literal: true

module EditorApp
  class HomeController < ApplicationController
    skip_authorization_check

    def show
      @school_student = current_user&.student?
    end
  end
end
