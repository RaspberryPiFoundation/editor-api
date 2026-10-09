# frozen_string_literal: true

module EditorApp
  # The editor web component is deployed to editor-static under a versioned
  # path. A deployment can point at a `latest_version` file holding the path of
  # the current release instead of naming a version, which has to be followed
  # before the script URL can be built.
  module WebComponent
    LATEST_VERSION = 'latest_version'
    CACHE_KEY = 'editor_app/web_component/latest_version'
    CACHE_EXPIRY = 5.minutes

    class << self
      def script_url
        "#{base_url}/web-component.js"
      end

      def base_url
        configured = ENV.fetch('EDITOR_WEB_COMPONENT_URL', '').chomp('/')
        return configured unless configured.end_with?(LATEST_VERSION)

        version = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY, skip_nil: true) do
          latest_version(configured)
        end
        version ? configured.sub(LATEST_VERSION, version) : configured
      end

      private

      def latest_version(url)
        response = HttpClient.new(url) { |f| f.response :raise_error }.get
        response.body.strip.presence
      rescue Faraday::Error => e
        Sentry.capture_exception(e)
        nil
      end
    end
  end
end
