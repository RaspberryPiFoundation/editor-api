# frozen_string_literal: true

module Api
  class UserSettingsController < ApiController
    before_action :authorize_user

    def show
      user_setting = UserSetting.find_or_initialize_by(user_id: current_user.id)
      authorize! :read, user_setting

      render json: { settings: user_setting.merged_settings }, status: :ok
    end

    def update
      user_setting = save_user_setting

      if user_setting.errors.empty?
        render json: { settings: user_setting.merged_settings }, status: :ok
      else
        render json: { error: user_setting.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    private

    # Lock the row so concurrent updates don't overwrite each other.
    def save_user_setting
      authorize! :update, UserSetting.new(user_id: current_user.id)
      new_settings = settings_params
      user_setting = nil

      UserSetting.transaction do
        UserSetting.insert({ user_id: current_user.id }, unique_by: :user_id) # rubocop:disable Rails/SkipsModelValidations
        user_setting = UserSetting.lock.find_by!(user_id: current_user.id)

        user_setting.merge_settings(new_settings)
        raise ActiveRecord::Rollback unless user_setting.save
      end

      user_setting
    end

    def settings_params
      settings = params.require(:settings)
      raise ParameterError, 'settings must be an object' unless settings.is_a?(ActionController::Parameters)

      settings.to_unsafe_h
    end
  end
end
