# frozen_string_literal: true

require 'uri'

class SchoolEmailDomain < ApplicationRecord
  belongs_to :school

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :school_id }

  before_validation :validate_domain

  private

  def validate_domain
    self.domain = format_domain
  end

  def format_domain
    return if domain.nil?

    str = domain.to_s.strip.sub(/\A@+/, '')
    str = uri_host_if_http_url(str) || str
    return str.downcase
  end

  def uri_host_if_http_url(str)
    return unless str.match?(/\Ahttps?:\/\//i)

    uri = URI.parse(str)
    uri.host if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
