# frozen_string_literal: true

namespace :integration_tests do
  desc 'Trigger the learner-experience-integration-tests GitHub Actions workflow against the deployed test environment'
  task dispatch: :environment do
    next unless on_test_app?

    response = connection.post(dispatch_url, dispatch_payload)
    raise "GitHub dispatch API returned status #{response.status}" unless response.status == 204
  rescue StandardError => e
    Sentry.capture_exception(e)
  end

  def dispatch_url
    'https://api.github.com/repos/RaspberryPiFoundation/learner-experience-integration-tests/dispatches'
  end

  def on_test_app?
    ENV.fetch('HEROKU_APP_NAME') == 'editor-api-test'
  end

  def connection
    Faraday.new do |faraday|
      faraday.request :json
      faraday.headers = {
        'Accept' => 'application/vnd.github+json',
        'Authorization' => "Bearer #{ENV.fetch('LEARNER_EXPERIENCE_TESTS_DISPATCH_TOKEN')}"
      }
    end
  end

  def dispatch_payload
    sha = ENV.fetch('HEROKU_SLUG_COMMIT')

    {
      event_type: 'learner-experience-test',
      client_payload: {
        repo: 'editor-api',
        sha:,
        ref: 'main',
        commit_message: "https://github.com/RaspberryPiFoundation/editor-api/commit/#{sha}",
        deploy_url: ENV.fetch('HOST_URL'),
        triggered_at: Time.now.utc.iso8601
      }
    }
  end
end
