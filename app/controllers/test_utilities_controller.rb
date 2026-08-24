# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :ensure_allowed

  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  Rails.application.load_tasks if Rake::Task.tasks.empty?

  def reseed
    Rake::Task['test_seeds:destroy'].execute
    Rake::Task['test_seeds:create'].execute
    render json: { message: 'Database reseeded successfully.' }, status: :ok
  end

  def enable_feature
    Flipper.enable(feature_key)
    head :no_content
  end

  def disable_feature
    Flipper.disable(feature_key)
    head :no_content
  end

  private

  def ensure_allowed
    not_found unless allowed?
  end

  def not_found
    head :not_found
  end

  def allowed?
    api_key_valid? && host_allowed?
  end

  def api_key_valid?
    ENV['RESEED_API_KEY'].present? && request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY']
  end

  def host_allowed?
    ALLOWED_HOSTS.include?(request.host)
  end

  def feature_key
    params.expect(:feature_key)
  end
end
