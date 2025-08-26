# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  Rails.application.load_tasks if Rake::Task.tasks.empty?

  def reseed
    if reseed_allowed?
      Rake::Task['test_seeds:destroy'].execute
      Rake::Task['test_seeds:create'].execute
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
