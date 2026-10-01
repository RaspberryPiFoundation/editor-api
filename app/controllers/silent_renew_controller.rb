# frozen_string_literal: true

class SilentRenewController < ApplicationController
  layout false

  def start
    return head :forbidden unless current_user

    session[:silent_renew_state] = SecureRandom.hex(24)
    session[:silent_renew_verifier] = SecureRandom.hex(64)

    redirect_to authorize_url, allow_other_host: true
  end

  def callback
    state = session.delete(:silent_renew_state)
    verifier = session.delete(:silent_renew_verifier)

    @renewed = params[:code].present? && matching_state?(state) && renew(params[:code], verifier)
  end

  private

  def matching_state?(state)
    state.present? && ActiveSupport::SecurityUtils.secure_compare(params[:state].to_s, state)
  end

  def renew(code, verifier)
    token = EditorHydraClient.oauth_client.auth_code.get_token(
      code, redirect_uri: silent_renew_url, code_verifier: verifier
    )

    self.current_user = User.from_id_token(token.params['id_token'], token.token)
    session[:oauth_expires_at] = token.expires_at
    true
  rescue OAuth2::Error => e
    Rails.logger.info { "Silent renew failed: #{e.message}" }
    false
  end

  def authorize_url
    query = {
      client_id: EditorHydraClient.client_id,
      redirect_uri: silent_renew_url,
      response_type: 'code',
      scope: EditorHydraClient::SCOPE,
      state: session[:silent_renew_state],
      prompt: 'none',
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }

    "#{EditorHydraClient.authorize_url}?#{query.to_query}"
  end

  def code_challenge
    Base64.urlsafe_encode64(Digest::SHA2.digest(session[:silent_renew_verifier]), padding: false)
  end
end
