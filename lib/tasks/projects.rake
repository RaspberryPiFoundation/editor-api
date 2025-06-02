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
        name: 'Experience CS example',
        user_id: nil
      },
      {
        identifier: 'dialogue-in-scratch',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Dialogue in Scratch',
        user_id: nil
      },
      {
        identifier: 'ten-block-mission',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Ten block mission',
        user_id: nil
      },
      {
        identifier: 'blank-scratch-starter',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Blank Scratch starter',
        user_id: nil
      },
      {
        identifier: 'lets-explore-scratch',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: "Let's explore Scratch",
        user_id: nil
      },
      {
        identifier: 'transforming-sprites',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Transforming sprites',
        user_id: nil
      }
    ]
    projects.each do |attributes|
      identifier = attributes[:identifier]
      project = Project.unscoped.find_by(attributes.slice(:identifier, :locale, :project_type))
      if project.present?
        puts "Scratch project with identifier '#{identifier}' already exists"
        project.assign_attributes(attributes.except(:identifier, :locale))
        if project.changed?
          if project.save
            puts "Scratch project with identifier '#{identifier}' updated successfully"
          else
            puts "Scratch project with identifier '#{identifier}' update failed"
          end
        else
          puts "Scratch project with identifier '#{identifier}' has not changed"
        end
      elsif Project.create(attributes)
        puts "Scratch project with identifier '#{identifier}' created successfully"
      else
        puts "Scratch project with identifier '#{identifier}' creation failed"
      end
    end
  end
end
