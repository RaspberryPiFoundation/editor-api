# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  def reseed
    abort('Not permitted to reseed in production') if Rails.env.production?

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
    api_key_valid? && environment_allowed? && host_allowed?
  end

  def api_key_valid?
    ENV['RESEED_API_KEY'].present? && request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY']
  end

  def environment_allowed?
    Rails.env.development? || Rails.env.test?
  end

  def host_allowed?
    ALLOWED_HOSTS.include?(request.host)
  end
end
