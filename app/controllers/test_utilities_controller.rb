# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  def reseed
    # rubocop:disable Rails/Output
    pp 'api_key_valid?', api_key_valid?
    pp 'api_key_present?', ENV['RESEED_API_KEY'].present?
    pp 'api_key_correct?', request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY']
    pp 'environment_allowed?', environment_allowed?
    pp 'environment', Rails.env
    pp 'host_allowed?', host_allowed?
    pp 'host', request.host
    # rubocop:enable Rails/Output

    if reseed_allowed?
      Rails.application.load_tasks
      Rake::Task['test_seeds:destroy'].invoke
      Rake::Task['test_seeds:create'].invoke
      render json: { message: 'Database reseeded successfully.' }, status: :ok
    else
      head :not_found
    end
  end

  private

  def reseed_allowed?
    api_key_valid? && host_allowed?
  end

  def api_key_valid?
    ENV['RESEED_API_KEY'].present? && request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY']
  end

  def host_allowed?
    ALLOWED_HOSTS.include?(request.host)
  end
end
