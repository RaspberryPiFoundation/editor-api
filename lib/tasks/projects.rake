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
        identifier: 'a-familar-tune',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'A Familar Tune',
        user_id: nil
      },
      {
        identifier: 'blank-scratch-starter',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Blank Scratch Starter',
        user_id: nil
      },
      {
        identifier: 'broadcasting-chords',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Broadcasting Chords',
        user_id: nil
      },
      {
        identifier: 'chord-detectives',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Chord Detectives',
        user_id: nil
      },
      {
        identifier: 'comparing-programs',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Comparing Programs',
        user_id: nil
      },
      {
        identifier: 'counting-with-variables',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Counting With Variables',
        user_id: nil
      },
      {
        identifier: 'creating-a-program',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Creating A Program',
        user_id: nil
      },
      {
        identifier: 'creating-clones',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Creating Clones',
        user_id: nil
      },
      {
        identifier: 'creating-programs',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Creating Programs',
        user_id: nil
      },
      {
        identifier: 'debug-it',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Debug It',
        user_id: nil
      },
      {
        identifier: 'debugging-in-scratch',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Debugging In Scratch',
        user_id: nil
      },
      {
        identifier: 'dialogue-in-scratch',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Dialogue In Scratch',
        user_id: nil
      },
      {
        identifier: 'digit-dash',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Digit Dash',
        user_id: nil
      },
      {
        identifier: 'experience-cs-example',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Experience Cs Example',
        user_id: nil
      },
      {
        identifier: 'getting-started-1',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Getting Started 1',
        user_id: nil
      },
      {
        identifier: 'investigating-broadcasting',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Investigating Broadcasting',
        user_id: nil
      },
      {
        identifier: 'lets-explore-scratch',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Lets Explore Scratch',
        user_id: nil
      },
      {
        identifier: 'lets-loop-it',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Lets Loop It',
        user_id: nil
      },
      {
        identifier: 'ma-testing',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Ma Testing',
        user_id: nil
      },
      {
        identifier: 'modifying-picture-graphs',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Modifying Picture Graphs',
        user_id: nil
      },
      {
        identifier: 'modifying-programs',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Modifying Programs',
        user_id: nil
      },
      {
        identifier: 'move-with-purpose',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Move With Purpose',
        user_id: nil
      },
      {
        identifier: 'my-anti-app',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'My Anti App',
        user_id: nil
      },
      {
        identifier: 'my-digital-canvas',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'My Digital Canvas',
        user_id: nil
      },
      {
        identifier: 'my-first-function',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'My First Function',
        user_id: nil
      },
      {
        identifier: 'my-simulation',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'My Simulation',
        user_id: nil
      },
      {
        identifier: 'mystery-story',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Mystery Story',
        user_id: nil
      },
      {
        identifier: 'paper-airplane-simulation',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Paper Airplane Simulation',
        user_id: nil
      },
      {
        identifier: 'pedestrian-button',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Pedestrian Button',
        user_id: nil
      },
      {
        identifier: 'pollination-patrol',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Pollination Patrol',
        user_id: nil
      },
      {
        identifier: 'programming-functions',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Programming Functions',
        user_id: nil
      },
      {
        identifier: 'programming-progressions',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Programming Progressions',
        user_id: nil
      },
      {
        identifier: 'sensing-motion',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Sensing Motion',
        user_id: nil
      },
      {
        identifier: 'sequence-a-melody',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Sequence A Melody',
        user_id: nil
      },
      {
        identifier: 'sequencing-programs',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Sequencing Programs',
        user_id: nil
      },
      {
        identifier: 'taking-a-tour',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Taking A Tour',
        user_id: nil
      },
      {
        identifier: 'ten-block-mission',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Ten Block Mission',
        user_id: nil
      },
      {
        identifier: 'the-me-project',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'The Me Project',
        user_id: nil
      },
      {
        identifier: 'the-vanishing-garden',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'The Vanishing Garden',
        user_id: nil
      },
      {
        identifier: 'time-travelers',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Time Travelers',
        user_id: nil
      },
      {
        identifier: 'traffic-light-timer',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Traffic Light Timer',
        user_id: nil
      },
      {
        identifier: 'transforming-sprites',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Transforming Sprites',
        user_id: nil
      },
      {
        identifier: 'weather-data',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Weather Data',
        user_id: nil
      },
      {
        identifier: 'word-art',
        locale: 'en',
        project_type: Project::Types::SCRATCH,
        name: 'Word Art',
        user_id: nil
      }
    ]
    projects.each do |attributes|
      identifier = attributes[:identifier]
      project = Project.find_by(attributes.slice(:identifier, :locale, :project_type))
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
