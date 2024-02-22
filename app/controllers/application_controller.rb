# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include AuthenticationHelper
  # include SwitchLocale
  
  # def default_url_options
  #   { locale: I18n.locale }
  # end
end
