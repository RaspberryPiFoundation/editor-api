# frozen_string_literal: true

require 'administrate/field/base'

class ResultsSummaryField < Administrate::Field::Base
  def to_s
    "#{successful_count} successful, #{failed_count} failed"
  end

  def successful_count
    data['successful']&.count || 0
  end

  def failed_count
    data['failed']&.count || 0
  end

  def total_count
    successful_count + failed_count
  end
end
