# frozen_string_literal: true

module Api
  class SubscriptionsController < ApiController
    before_action :check_cloudflare_turnstile, only: :create

    API_URL = 'https://challenges.cloudflare.com/turnstile/v0/siteverify'

    def create
      payload = subscription_params.to_h
      errors = validation_errors_for(payload)

      if errors.empty?
        submit_result = subscriptions_submitter.call(form_payload: payload)
        if submit_result.success?
          Rails.logger.info('[subscriptions#create] outcome=success')
          render json: {
            ok: true,
            message: 'Subscription accepted',
            subscription: payload
          }, status: :ok
        else
          Rails.logger.warn(
            "[subscriptions#create] outcome=failure error_code=#{submit_result.error_code}"
          )
          render json: {
            ok: false,
            error_code: submit_result.error_code,
            message: submit_result.message
          }, status: submit_result.status
        end
      else
        Rails.logger.warn('[subscriptions#create] outcome=failure error_code=subscription_validation_failed')
        render json: {
          ok: false,
          error_code: 'subscription_validation_failed',
          message: 'Subscription rejected due to invalid input',
          errors:,
          subscription: payload
        }, status: :unprocessable_content
      end
    end

    private

    def check_cloudflare_turnstile
      return unless Rails.configuration.x.cloudflare_turnstile.enabled
      return if valid_turnstile_token?

      Rails.logger.warn('[subscriptions#create] outcome=failure error_code=turnstile_verification_failed')
      render json: {
        ok: false,
        error_code: 'turnstile_verification_failed',
        message: 'Bot protection check failed. Please try again.'
      }, status: :unprocessable_content
    end

    def valid_turnstile_token?
      token = params.dig(:subscription, :turnstile_token)
      return false if token.blank?

      response = Faraday.post(
        API_URL,
        {
          secret: Rails.configuration.x.cloudflare_turnstile.secret_key,
          response: token,
          remoteip: request.remote_ip
        }
      )
      JSON.parse(response.body)['success'] == true
    rescue StandardError
      # Fail open to allow the request through if verification is unavailable
      # due to network issues, Cloudflare downtime or malformed responses etc.
      true
    end

    def subscription_params
      params.require(:subscription).permit(:email, :test_opt_in, :privacy_policy)
    end

    def subscriptions_submitter
      @subscriptions_submitter ||= Subscriptions::PardotFormHandlerSubmitter.new(
        endpoint_url: Rails.configuration.x.subscriptions.pardot_form_handler_url
      )
    end

    def validation_errors_for(payload)
      errors = []
      errors << 'email is required' if payload['email'].blank?
      errors << 'email is invalid' if payload['email'].present? && !valid_email?(payload['email'])
      errors << 'privacy_policy must be true' unless payload['privacy_policy'] == true
      errors
    end

    def valid_email?(email)
      # Keep codebase-consistent validator and also require a dot in the domain.
      email.match?(EmailValidator.regexp) && email.split('@').last&.include?('.')
    end
  end
end
