# frozen_string_literal: true

module Api
  class GoogleAuthController < ApiController
    TOKEN_EXCHANGE_URL = 'https://oauth2.googleapis.com/token'

    before_action :authorize_user
    authorize_resource :google_auth, class: false

    def exchange_code
      payload = google_token_params

      request_body = {
        code: payload[:code],
        client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
        client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET'),
        redirect_uri: payload[:redirect_uri],
        grant_type: 'authorization_code'
      }

      conn = Faraday.new do |f|
        f.request :url_encoded
        f.options.timeout = 10      # connection open timeout
        f.options.open_timeout = 5  # connection initialization timeout
      end

      response = conn.post(TOKEN_EXCHANGE_URL, request_body)
      @token_response = JSON.parse(response.body)

      if response.success?
        render :exchange_code, status: :ok
      else
        render json: { error: @token_response['error_description'] }, status: :unauthorized
      end
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :service_unavailable
    end

    private

    def google_token_params
      params.require(:google_auth).require(:code)
      params.require(:google_auth).require(:redirect_uri)
      params.require(:google_auth).permit(:code, :redirect_uri)
    end
  end
end
