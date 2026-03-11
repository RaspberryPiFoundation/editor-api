# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include RpiAuth::Controllers::CurrentUser
end
