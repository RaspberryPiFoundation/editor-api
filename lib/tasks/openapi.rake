# frozen_string_literal: true

namespace :openapi do
  desc 'Auto-generate OpenAPI docs from all request specs'
  task generate: :environment do
    puts 'Generating comprehensive OpenAPI spec from all specs...'
    # Include spec/requests/api/ (new API specs), spec/requests/projects/ (original), and spec/features/ (school-related specs)
    sh 'OPENAPI=1 bundle exec rspec spec/requests/api/ spec/requests/projects/ spec/requests/project_errors_spec.rb spec/features/ --format progress'
    puts "\n✅ OpenAPI spec generated at swagger/v1/swagger.yaml"
    puts 'View at: http://localhost:3009/api-docs'
  end

  desc 'Regenerate only for specific spec file'
  task generate_one: :environment do |_t, args|
    spec_file = args[:spec_file] || ENV.fetch('SPEC', nil)
    if spec_file
      puts "Generating OpenAPI spec from #{spec_file}..."
      sh "OPENAPI=1 bundle exec rspec #{spec_file} --format progress"
      puts "\n✅ OpenAPI spec updated"
    else
      puts 'Usage: rake openapi:generate_one[spec/requests/projects/show_spec.rb]'
      puts '   or: SPEC=spec/requests/projects/show_spec.rb rake openapi:generate_one'
    end
  end
end
