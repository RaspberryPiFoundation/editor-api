# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  def reseed
    # rubocop:disable Rails/Output
    pp 'api_key_valid?', api_key_valid?
    pp 'api_key_present?', ENV['RESEED_API_KEY'].present?
    pp 'api_key_correct?', request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY']
    pp 'host_allowed?', host_allowed?
    pp 'host', request.host
    pp 'reseed_allowed?', reseed_allowed?

    if reseed_allowed?
      pp 'reseed was allowed'
      Rails.application.load_tasks
      pp 'destroying seeds...'
      Rake::Task['test_seeds:destroy'].invoke
      pp 'creating seeds...'
      Rake::Task['test_seeds:create'].invoke
      pp 'success!'
      render json: { message: 'Database reseeded successfully.' }, status: :ok
      # rubocop:enable Rails/Output
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
