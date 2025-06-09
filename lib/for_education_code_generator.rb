# frozen_string_literal: true

class ForEducationCodeGenerator
  MAX_CODE = 1_000_000

  cattr_accessor :random

  self.random ||= Random.new

  def self.generate
    number = random.rand(MAX_CODE)
    code = format('%06d', number)

    code.match(/(\d\d)(\d\d)(\d\d)/) do |m|
      [m[1], m[2], m[3]].join('-')
    end
  end
end
