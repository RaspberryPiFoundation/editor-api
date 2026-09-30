# frozen_string_literal: true

module EditorApp
  class LocalesController < ApplicationController
    skip_authorization_check

    def show
      redirect_to home_path
    end
  end
end
