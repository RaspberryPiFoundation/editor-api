# frozen_string_literal: true

namespace :swagger do
  desc 'Generate swagger documentation from specs in spec/swagger/'
  task :generate do
    sh 'rake rswag:specs:swaggerize PATTERN="spec/swagger/**/*_spec.rb"'
  end
end
