# frozen_string_literal: true

class SchoolEmailDomain < ApplicationRecord
  belongs_to :school

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :school_id }

  before_validation :normalise_domain
  validate :validate_public_suffix

  private

  def normalise_domain
    return if domain.nil?

    self.domain = build_normalised_domain_string(domain)
  end

  # Uses the Public Suffix List via the public_suffix gem: values must be a real
  # hostname with a registrable name, not a bare suffix like com or co.uk.
  # https://publicsuffix.org
  def validate_public_suffix
    return if domain.blank?

    errors.add(:domain, :invalid) unless PublicSuffix.valid?(domain)
  end

  def build_normalised_domain_string(raw)
    str = raw.to_s.strip.sub(/\A@+/, '')
    str = uri_host_if_http_url(str) || str
    str.downcase
  end

  def uri_host_if_http_url(str)
    return unless str.match?(%r{\Ahttps?://}i)

    uri = URI.parse(str)
    uri.host if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end
