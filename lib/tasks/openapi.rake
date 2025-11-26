# frozen_string_literal: true

namespace :openapi do
  desc 'Auto-generate OpenAPI docs from ALL request and feature specs'
  task generate: :environment do
    puts 'Generating comprehensive OpenAPI spec from all specs...'
    sh 'OPENAPI=1 bundle exec rspec spec/requests/ spec/features/ --format progress'
    puts "\n✅ OpenAPI spec generated at swagger/v1/swagger.yaml"
    puts 'View at: http://localhost:3009/api-docs'
  end

  desc 'Generate OpenAPI docs from only request specs (projects, google auth)'
  task generate_requests_only: :environment do
    puts 'Generating OpenAPI spec from spec/requests/ only...'
    sh 'OPENAPI=1 bundle exec rspec spec/requests/ --format progress'
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
