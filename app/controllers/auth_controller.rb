# frozen_string_literal: true

class AuthController < ApplicationController
  # def index

  # end

  def callback
    Rails.logger.debug { "callback: #{omniauth_params}" }
    # Prevent session fixation.  If the session has been initialized before
    # this, and we need to keep the data, then we should copy values over.
    reset_session

    self.current_user = User.from_omniauth request.env['omniauth.auth']

    return redirect_to admin_root_path if current_user.admin?

    redirect_to root_path
  end

  def destroy
    reset_session

    # Prevent redirect loops etc.
    if ENV.fetch('BYPASS_OAUTH', nil) == 'true'
      redirect_to root_path
      return
    end

    redirect_to "#{ENV.fetch('IDENTITY_URL', nil)}/logout?returnTo=#{ENV.fetch('HOST_URL', nil)}",
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

  def omniauth_params
    request.env['omniauth.params']
  end
end
