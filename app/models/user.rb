class User < ApplicationRecord
  include RpiAuth::Models::Authenticatable
  # include ActiveModel::Model
  # frozen_string_literal: true
end
