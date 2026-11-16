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

    # The row is created on the first update. If two first updates race, the
    # unique index on user_id rejects one; retry it so it updates the new row.
    def save_user_setting(retries: 1)
      user_setting = UserSetting.find_or_initialize_by(user_id: current_user.id)
      authorize! :update, user_setting

      user_setting.merge_settings(settings_params)
      user_setting.save
      user_setting
    rescue ActiveRecord::RecordNotUnique
      raise if retries.zero?

      save_user_setting(retries: retries - 1)
    end

    # Keys and values are validated against UserSetting::REGISTRY by the model,
    # so unknown keys return 422 rather than being silently dropped.
    def settings_params
      settings = params.require(:settings)
      raise ParameterError, 'settings must be an object' unless settings.is_a?(ActionController::Parameters)

      settings.to_unsafe_h
    end
  end
end
