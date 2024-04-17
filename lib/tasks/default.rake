# frozen_string_literal: true

return if Rails.env.production?

Rake::Task[:default].clear_prerequisites
task default: %i[rubocop spec]
