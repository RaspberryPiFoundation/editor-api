# frozen_string_literal: true

class SchoolEmailDomain < ApplicationRecord
  belongs_to :school

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :school_id }

  before_validation :validate_domain

  private

  def validate_domain
    return if domain.blank?

    value = domain.strip.downcase
    # Add a scheme unless it already has one, so URI can parse it
    value = "http://#{value}" unless %r{\A[a-z][a-z0-9+\-.]*://}i.match?(value)
    uri = URI.parse(value)
    host = uri.host&.delete_suffix('.')
    return if host.blank?

    if PublicSuffix.valid?(host)
      self.domain = host
    else
      errors.add(:domain, :invalid)
    end
  rescue URI::InvalidURIError
    errors.add(:domain, :invalid)
  end
end
