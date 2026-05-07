# frozen_string_literal: true

module SchoolEmailDomainValidator
  class Error < StandardError
    def error_code
      :invalid
    end
  end

  class BlankDomainError < Error
    def error_code
      :blank
    end
  end

  class InvalidURIError < Error
    def error_code
      :invalid_uri
    end
  end

  class InvalidHostError < Error
    def error_code
      :invalid_host
    end
  end

  class PublicSuffixError < Error
    def error_code
      :invalid_public_suffix
    end
  end

  def self.call(domain)
    raise BlankDomainError if domain.blank?

    validate_domain(domain)
  end

  def self.validate_domain(domain)
    value = domain.strip.downcase
    # Add a scheme unless it already has one, so URI can parse it
    value = "http://#{value}" unless %r{\A[a-z][a-z0-9+\-.]*://}i.match?(value)
    uri = URI.parse(value)
    host = uri.host&.delete_suffix('.')

    validate_host(host)
  rescue URI::InvalidURIError
    raise InvalidURIError
  end

  def self.validate_host(host)
    accounts_host_format =
      /\A\s*(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}\s*\z/i

    raise InvalidHostError unless host&.match?(accounts_host_format)

    raise PublicSuffixError, 'domain has no registered public suffix' unless PublicSuffix.valid?(host)

    host
  end
end
