# frozen_string_literal: true

module Api
  class SubscriptionsController < ApiController
    def create
      payload = subscription_params.to_h
      errors = validation_errors_for(payload)

      Rails.logger.warn(
        "[subscriptions#create] payload=#{payload.inspect} result=#{errors.empty? ? 'success' : 'failure'}"
      )

      if errors.empty?
        submit_result = subscriptions_submitter.call(subscription_payload: payload)
        if submit_result.success?
          render json: {
            ok: true,
            message: 'Subscription accepted',
            subscription: payload
          }, status: :ok
        else
          render json: {
            ok: false,
            error_code: submit_result.error_code,
            message: submit_result.message
          }, status: submit_result.status
        end
      else
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

    def subscription_params
      params.require(:subscription).permit(:email, :test_opt_in, :privacy_policy)
    end

    def subscriptions_submitter
      @subscriptions_submitter ||= Subscriptions::PardotApiSubmitter.new(
        subscription_url: Rails.configuration.x.subscriptions.pardot_api_subscription_url,
        business_unit_id: Rails.configuration.x.subscriptions.pardot_business_unit_id,
        token_provider: subscriptions_token_provider
      )
    end

    def subscriptions_token_provider
      @subscriptions_token_provider ||= Subscriptions::PardotTokenProvider.new(
        auth_url: Rails.configuration.x.subscriptions.pardot_auth_url,
        client_id: Rails.configuration.x.subscriptions.pardot_client_id,
        client_secret: Rails.configuration.x.subscriptions.pardot_client_secret,
        scope: Rails.configuration.x.subscriptions.pardot_auth_scope
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
