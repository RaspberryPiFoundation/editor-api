# frozen_string_literal: true

require 'rake'

if Rails.env.development?
  Rake::Task['projects:create_all'].invoke
  Rake::Task['for_education:seed_a_school_with_lessons_and_students'].invoke
  Rake::Task['projects:create_experience_cs_examples'].invoke
end
