# frozen_string_literal: true

namespace :projects do
  desc 'Import starter & example projects'
  task create_all: :environment do
    FilesystemProject.import_all!
  end

  desc "Create example Scratch projects for Experience CS (if they don't already exist)"
  task create_experience_cs_examples: :environment do
    projects = [
      {
        identifier: 'experience-cs-example',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Experience CS Example',
        user_id: nil
      },
      {
        identifier: 'ten-block-mission',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: '10 Block Mission',
        user_id: nil
      }
    ]
    projects.each do |attributes|
      if Project.unscoped.exists?(attributes.slice(:identifier, :locale))
        puts 'Scratch project already exists'
      elsif Project.create(attributes)
        puts 'Scratch project created successfully'
      else
        puts 'Scratch project creation failed'
      end
    end
  end
end
