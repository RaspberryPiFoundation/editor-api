# frozen_string_literal: true

# Ensure Semantic Logger is used in all cases by updating cached references to the standard logger.
Rails.application.config.after_initialize do
  ActiveSupport::LogSubscriber.logger = Rails.logger
  Rails.application.env_config['action_dispatch.logger'] = Rails.logger
end
