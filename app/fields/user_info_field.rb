# frozen_string_literal: true

require 'administrate/field/base'

class UserInfoField < Administrate::Field::Base
  def to_s
    user_display
  end

  def user_display
    return 'Unknown User' if data.blank?

    user_info = fetch_user_info
    return data if user_info.nil?

    if user_info[:name].present? && user_info[:email].present?
      "#{user_info[:name]} <#{user_info[:email]}>"
    elsif user_info[:name].present?
      user_info[:name]
    elsif user_info[:email].present?
      user_info[:email]
    else
      data
    end
  end

  def user_name
    return nil if data.blank?

    user_info = fetch_user_info
    user_info&.dig(:name)
  end

  def user_email
    return nil if data.blank?

    user_info = fetch_user_info
    user_info&.dig(:email)
  end

  def user_id
    data
  end

  private

  def fetch_user_info
    return @fetch_user_info if defined?(@fetch_user_info)

    @fetch_user_info = begin
      # Try to get from request-level cache first (set by controller)
      cache = RequestStore.store[:user_info_cache] || {}
      cached = cache[data]

      if cached
        cached
      else
        # Fallback to individual API call if not in cache
        result = UserInfoApiClient.fetch_by_ids([data])
        result&.first
      end
    rescue StandardError => e
      Rails.logger.error("Failed to fetch user info for #{data}: #{e.message}")
      nil
    end
  end
end
