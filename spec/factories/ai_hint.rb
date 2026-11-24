# frozen_string_literal: true

FactoryBot.define do
  factory :ai_hint do
    user_id { SecureRandom.uuid }
    input { { 'message' => 'NameError', 'trace' => 'line 1', 'runtime' => 'python', 'code' => 'print(x)' } }
  end
end
