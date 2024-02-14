# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # include RpiAuth::Controllers::CurrentUser
  include AuthenticationHelper
  # include Identifiable
  # helper_method :current_user
end
