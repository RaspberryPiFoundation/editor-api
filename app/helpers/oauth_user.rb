module OauthUser
  def oauth_user_id
    @oauth_user_id ||= fetch_oauth_user_id
  end

  private

  def fetch_oauth_user_id
    return nil if request.headers['Authorization'].blank?

    con = Faraday.new ENV.fetch('HYDRA_ADMIN_URL')
    res = con.post do |req|
      req.url '/oauth2/introspect'
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.headers['Authorization'] = "Basic #{ENV.fetch('HYDRA_SECRET')}"
      req.body = { token: request.headers['Authorization'] }
    end
    json = JSON.parse(res.body)
    json['sub']
  end
end
