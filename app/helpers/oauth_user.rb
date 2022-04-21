# frozen_string_literal: true

module OauthUser
  def oauth_user_id
    @oauth_user_id ||= fetch_oauth_user_id
  end

  private

  def fetch_oauth_user_id
    return nil if request.headers['Authorization'].blank?

    return AUTH_USER_ID if BYPASS_AUTH

    json = hydra_request
    json['sub']
  end

  def hydra_request
    con = Faraday.new ENV.fetch('HYDRA_ADMIN_URL')
    res = con.post do |req|
      req.url '/oauth2/introspect'
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.headers['apiKey'] = ENV.fetch('HYDRA_SECRET')
      req.body = { token: request.headers['Authorization'] }
    end
    JSON.parse(res.body)
  end
end
