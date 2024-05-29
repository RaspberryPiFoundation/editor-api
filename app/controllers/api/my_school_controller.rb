# frozen_string_literal: true

module Api
  class MySchoolController < ApiController
    before_action :authorize_user

    def show
      @school = School.find_for_user!(current_user)
      @user = current_user
      render :show, formats: [:json], status: :ok
    end
  end
end
