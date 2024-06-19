# frozen_string_literal: true

require 'rake'

unless Rails.env.development?
  Rails.logger.info 'This task can only be run in the development environment.'
  exit
end

Rake::Task['classroom_management:seed_a_school_with_lessons'].invoke
