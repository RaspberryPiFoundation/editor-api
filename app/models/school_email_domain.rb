# frozen_string_literal: true

class SchoolEmailDomain < ApplicationRecord
  belongs_to :school

  validates :domain, presence: true
  validates :domain, uniqueness: { scope: :school_id }

  before_validation :format_domain

  private

  def format_domain
    return if domain.nil?

    self.domain = domain.to_s.strip.sub(/\A@+/, '').downcase
  end
end
