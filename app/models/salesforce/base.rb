# # frozen_string_literal: true

module Salesforce
  class Base < ApplicationRecord
    self.abstract_class = true

    connects_to database: { writing: :salesforce_connect }
  end
end
