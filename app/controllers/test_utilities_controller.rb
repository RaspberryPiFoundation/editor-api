# frozen_string_literal: true

class TestUtilitiesController < ApplicationController
  skip_before_action :verify_authenticity_token
  ALLOWED_HOSTS = ['test-editor-api.raspberrypi.org', 'localhost'].freeze

  def reseed
    if ENV['RESEED_API_KEY'].present? &&
       request.headers['X-RESEED-API-KEY'] == ENV['RESEED_API_KEY'] &&
       (Rails.env.development? || Rails.env.test?) &&
       ALLOWED_HOSTS.include?(request.host)
      Rails.application.load_tasks
      Rake::Task['test_seeds:destroy'].invoke
      Rake::Task['test_seeds:create'].invoke
      render json: { message: 'Database reseeded successfully.' }, status: :ok
    else
      head :not_found
    end
  end
end
