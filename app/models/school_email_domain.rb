# frozen_string_literal: true

class SchoolEmailDomain < ApplicationRecord
  belongs_to :school

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :school_id }

  before_validation :validate_domain

  private

  def validate_domain
    self.domain = SchoolEmailDomainValidator.call(domain)
  rescue ::SchoolEmailDomainValidator::Error => e
    errors.add(:domain, e.error_code)
  end
end
