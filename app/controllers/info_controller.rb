# frozen_string_literal: true

class InfoController < ActionController::API
  def release
    render plain: ENV.fetch('HEROKU_SLUG_COMMIT', 'unknown')
  end
end
