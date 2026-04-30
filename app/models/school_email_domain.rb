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

    validate_host(host)
  rescue URI::InvalidURIError
    errors.add(:domain, :invalid)
  end

  def validate_host(host)
    accounts_host_format =
      /\A\s*(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}\s*\z/i

    unless host&.match?(accounts_host_format)
      errors.add(:domain, :invalid)
      return
    end

    if PublicSuffix.valid?(host)
      self.domain = host
    else
      errors.add(:domain, :invalid)
    end
  end
end
