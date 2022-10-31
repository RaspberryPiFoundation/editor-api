# frozen_string_literal: true

BYPASS_AUTH = ENV['BYPASS_AUTH'] == 'true'
AUTH_USER_ID = ENV.fetch('AUTH_USER_ID', nil) if BYPASS_AUTH
