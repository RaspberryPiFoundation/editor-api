# frozen_string_literal: true

class AuthController < ApplicationController
  LOCAL_PATH = %r{\A/(?![\\/])}

  def callback
    Rails.logger.debug { "callback: #{omniauth_params}" }
    # Prevent session fixation.  If the session has been initialized before
    # this, and we need to keep the data, then we should copy values over.
    reset_session

    self.current_user = User.from_omniauth request.env['omniauth.auth']
    session[:oauth_expires_at] = request.env.dig('omniauth.auth', 'credentials', 'expires_at')

    redirect_to post_login_path
  end

  def destroy
    reset_session

    # Prevent redirect loops etc.
    if ENV['BYPASS_OAUTH'].present?
      redirect_to root_path
      return
    end

    redirect_to "#{ENV.fetch('IDENTITY_URL', nil)}/logout?returnTo=#{logout_return_url}",
                allow_other_host: true
  end

  def failure
    flash[:alert] = if request.env['omniauth.error.type'] == :not_verified
                      'Login error - account not verified'
                    else
                      'Login error message'
                    end

    redirect_to root_path
  end

  private

  def post_login_path
    return login_origin if login_origin
    return admin_root_path if current_user.admin?

    root_path
  end

  def login_origin
    origin = request.env['omniauth.origin'].to_s
    origin if origin.match?(LOCAL_PATH)
  end

  def logout_return_url
    return request.base_url if EditorApp.serves_host?(request.host)

    ENV.fetch('HOST_URL', nil)
  end

  def omniauth_params
    request.env['omniauth.params']
  end
end
