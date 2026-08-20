# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'integration_tests', type: :task do
  describe ':dispatch' do
    let(:task) { Rake::Task['integration_tests:dispatch'] }
    let(:dispatch_url) { 'https://api.github.com/repos/RaspberryPiFoundation/learner-experience-integration-tests/dispatches' }
    let(:heroku_app_name) { 'editor-api-test' }
    let(:host_url) { 'https://test-editor-api.raspberrypi.org' }
    let(:sha) { SecureRandom.hex(20) }
    let(:token) { 'dispatch-token' }
    let(:env) do
      {
        'HEROKU_APP_NAME' => heroku_app_name,
        'HEROKU_SLUG_COMMIT' => sha,
        'HOST_URL' => host_url,
        'LEARNER_EXPERIENCE_TESTS_DISPATCH_TOKEN' => token
      }
    end

    around { |example| ClimateControl.modify(env) { example.run } }

    before do
      stub_request(:post, dispatch_url).to_return(status: 204)
    end

    context 'when HEROKU_APP_NAME is editor-api-test' do
      it 'dispatches the workflow with the expected payload and auth header' do
        task.invoke

        expect(WebMock).to have_requested(:post, dispatch_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{token}",
              'Accept' => 'application/vnd.github+json'
            },
            body: {
              event_type: 'learner-experience-test',
              client_payload: {
                repo: 'editor-api',
                sha:,
                ref: 'main',
                commit_message: "https://github.com/RaspberryPiFoundation/editor-api/commit/#{sha}",
                deploy_url: host_url,
                triggered_at: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
              }
            }
          )
      end
    end

    context 'when HEROKU_APP_NAME is not editor-api-test' do
      let(:heroku_app_name) { 'editor-api-staging' }

      it 'does not dispatch the workflow' do
        task.invoke

        expect(WebMock).not_to have_requested(:post, dispatch_url)
      end
    end

    context 'when a required env var is missing' do
      let(:env) { super().merge('HEROKU_SLUG_COMMIT' => nil) }

      it 'does not raise' do
        expect { task.invoke }.not_to raise_error
      end

      it 'reports the error to Sentry' do
        allow(Sentry).to receive(:capture_exception)

        task.invoke

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(KeyError))
      end
    end

    context 'when the request fails' do
      before do
        stub_request(:post, dispatch_url).to_return(status: 500)
      end

      it 'does not raise' do
        expect { task.invoke }.not_to raise_error
      end

      it 'reports the error to Sentry' do
        allow(Sentry).to receive(:capture_exception)

        task.invoke

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(RuntimeError))
      end
    end

    context 'when an unexpected error is raised' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_raise(Faraday::ConnectionFailed, 'boom') # rubocop:disable RSpec/AnyInstance
      end

      it 'does not raise' do
        expect { task.invoke }.not_to raise_error
      end

      it 'reports the error to Sentry' do
        allow(Sentry).to receive(:capture_exception)

        task.invoke

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Faraday::ConnectionFailed))
      end
    end
  end
end
