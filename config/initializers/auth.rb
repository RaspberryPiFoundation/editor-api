# frozen_string_literal: true

BYPASS_AUTH = ENV['BYPASS_AUTH'] == 'true'
AUTH_USER_ID = ENV['AUTH_USER_ID'] if BYPASS_AUTH
