# frozen_string_literal: true

module EditorApp
  class EducationController < ApplicationController
    skip_authorization_check

    # The page this replaced existed only to tell teachers that Code Editor
    # for Education is now Code Classroom.
    def show
      redirect_to helpers.code_classroom_url("/#{I18n.locale}/school"), allow_other_host: true
    end
  end
end
