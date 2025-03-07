# frozen_string_literal: true

class ForEducationCodeGenerator
  MAX_CODE = 1_000_000

  def self.generate
    number = Random.new.rand(MAX_CODE)
    code = format('%06d', number)

    code.match(/(\d\d)(\d\d)(\d\d)/) do |m|
      [m[1], m[2], m[3]].join('-')
    end
  end
end
