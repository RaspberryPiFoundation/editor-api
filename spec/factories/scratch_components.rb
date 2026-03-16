# frozen_string_literal: true

FactoryBot.define do
  factory :scratch_component do
    content { { targets: [], monitors: [], extensions: [], meta: {} } }
    project
  end
end
