# frozen_string_literal: true

module Api
  class GoogleAuthController < ApiController
    TOKEN_EXCHANGE_URL = 'https://oauth2.googleapis.com/token'

    before_action :authorize_user
    authorize_resource :google_auth, class: false

    def exchange_code
      response = faraday.post(TOKEN_EXCHANGE_URL, token_exchange_payload)
      @token_response = JSON.parse(response.body)

      return render(:exchange_code, status: :ok) if response.success?

      render json: { error: response_error_message }, status: :unauthorized
    rescue JSON::ParserError => e
      render json: { error: e.message }, status: :bad_gateway
    rescue Faraday::Error => e
      render json: { error: e.message }, status: :service_unavailable
    end

    private

    def faraday
      Faraday.new do |f|
        f.request :url_encoded
        f.options.timeout = 10
        f.options.open_timeout = 5
      end
    end

    def token_exchange_payload
      payload = google_token_params
      {
        code: payload[:code],
        client_id: ENV.fetch('GOOGLE_CLIENT_ID'),
        client_secret: ENV.fetch('GOOGLE_CLIENT_SECRET'),
        redirect_uri: payload[:redirect_uri],
        grant_type: 'authorization_code'
      }
    end

    def response_error_message
      @token_response['error_description'] || @token_response['error'] || 'Unknown error'
    end

    def google_token_params
      params.require(:google_auth).require(:code)
      params.require(:google_auth).require(:redirect_uri)
      params.require(:google_auth).permit(:code, :redirect_uri)
    end
  end
end
