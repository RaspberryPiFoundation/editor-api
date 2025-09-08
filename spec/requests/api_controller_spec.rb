# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiController do
  let(:test_controller) do
    Class.new(ApiController) do
      cattr_accessor :authorize_user_required
      cattr_accessor :error

      def index
        authorize_user if self.class.authorize_user_required
        raise self.class.error if self.class.error.present?

        render json: {} unless performed?
      end
    end
  end

  before do
    stub_const('TestController', test_controller)

    Rails.application.routes.disable_clear_and_finalize = true

    Rails.application.routes.draw do
      get '/test', to: 'test#index'
    end
  end

  after do
    Rails.application.reload_routes!
  end

  context 'when ActionController::ParameterMissing is raised' do
    before do
      test_controller.error = ActionController::ParameterMissing.new('foo')
    end

    it 'responds with 400 Bad Request status code' do
      get '/test'

      expect(response).to have_http_status(:bad_request)
    end

    it 'responds with JSON including exception class & message' do
      get '/test'

      expect(response.parsed_body).to include(
        'error' => 'ActionController::ParameterMissing: param is missing or the value is empty: foo'
      )
    end
  end

  context 'when ActiveRecord::RecordNotFound is raised' do
    before do
      test_controller.error = ActiveRecord::RecordNotFound.new('foo')
    end

    it 'responds with 404 Not Found status code' do
      get '/test'

      expect(response).to have_http_status(:not_found)
    end

    it 'responds with JSON including exception class & message' do
      get '/test'

      expect(response.parsed_body).to include(
        'error' => 'ActiveRecord::RecordNotFound: foo'
      )
    end
  end

  context 'when CanCan::AccessDenied is raised' do
    before do
      test_controller.error = CanCan::AccessDenied.new('foo')
    end

    it 'responds with 403 Forbidden status code' do
      get '/test'

      expect(response).to have_http_status(:forbidden)
    end

    it 'responds with JSON including exception class & message' do
      get '/test'

      expect(response.parsed_body).to include(
        'error' => 'CanCan::AccessDenied: foo'
      )
    end
  end

  context 'when ParameterError is raised' do
    before do
      test_controller.error = ParameterError.new('foo')
    end

    it 'responds with 422 Unprocessable entity status code' do
      get '/test'

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'responds with JSON including exception class & message' do
      get '/test'

      expect(response.parsed_body).to include(
        'error' => 'ParameterError: foo'
      )
    end
  end

  context 'when an unhandled exception is raised' do
    let(:error) { RuntimeError.new('foo') }

    before do
      test_controller.error = error
      allow(Sentry).to receive(:capture_exception)
    end

    it 'reports exception to Sentry' do
      get '/test'

      expect(Sentry).to have_received(:capture_exception).with(error)
    end

    it 'responds with 500 Internal server error status code' do
      get '/test'

      expect(response).to have_http_status(:internal_server_error)
    end

    it 'responds with JSON including exception class & message' do
      get '/test'

      expect(response.parsed_body).to include(
        'error' => 'RuntimeError: foo'
      )
    end
  end

  context 'when authorize_user is called' do
    before do
      test_controller.authorize_user_required = true
    end

    context 'when current_user is set' do
      before do
        allow(User).to receive(:from_token).and_return(User.new)
      end

      it 'responds with 200 OK code' do
        get '/test', headers: { 'Authorization' => 'secret' }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when current_user is not set' do
      it 'responds with 401 Unauthorized status code' do
        get '/test'

        expect(response).to have_http_status(:unauthorized)
      end

      it 'responds with JSON including error message' do
        get '/test'

        expect(response.parsed_body).to include(
          'error' => 'Unauthorized'
        )
      end
    end
  end
end
