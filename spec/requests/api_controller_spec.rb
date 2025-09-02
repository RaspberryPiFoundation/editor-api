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
      test_controller.error = ActiveRecord::RecordNotFound.new
    end

    it 'responds with 404 Not Found status code' do
      get '/test'

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'when CanCan::AccessDenied is raised' do
    before do
      test_controller.error = CanCan::AccessDenied.new
    end

    it 'responds with 403 Forbidden status code' do
      get '/test'

      expect(response).to have_http_status(:forbidden)
    end
  end

  context 'when ParameterError is raised' do
    before do
      test_controller.error = ParameterError.new
    end

    it 'responds with 422 Unprocessable entity status code' do
      get '/test'

      expect(response).to have_http_status(:unprocessable_entity)
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
    end
  end
end
