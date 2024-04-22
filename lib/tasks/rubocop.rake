# frozen_string_literal: true

return if Rails.env.production?

require 'rubocop/rake_task'
RuboCop::RakeTask.new
