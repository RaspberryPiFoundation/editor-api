# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

# Note the use of the $ at the end of the regexes below, this ensures
# that the origins are matched exactly and not just a substring eg.
# match: https://www.example.com
# don't match: https://www.example.com.anotherdomain.com

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # localhost and test domain
    if Rails.env.development?
      origins(%r{https?://localhost([:0-9]*)$})
    elsif Rails.env.test?
      origins(%r{https?://localhost([:0-9]*)$}, %r{https?://www\.example\.com$})
    end

    standard_cors_options
  end

  # all raspberrypi.org subdomains (*.raspberry.org)
  allow do
    origins(%r{https?://.+\.raspberrypi\.org$})

    standard_cors_options
  end

  # Cloudflare Pages static
  allow do
    origins('https://editor-standalone-eyq.pages.dev', 'https://block-to-text-alpha.pages.dev', 'https://projects-ui.pages.dev')

    standard_cors_options
  end

  # Cloudflare Pages dynamic (*.editor-standalone-eyq.pages.dev and *.projects-ui.pages.dev)
  allow do
    origins(%r{https?://.+\.editor-standalone-eyq\.pages\.dev$}, %r{https?://.+\.projects-ui\.pages\.dev$})

    standard_cors_options
  end

  # Oak
  allow do
    origins('https://preview.courses.edx.org', 'https://studio.edx.org')

    standard_cors_options
  end
end

def standard_cors_options
  resource '*', headers: :any, methods: %i[get post patch put delete], expose: ['Link']
end
