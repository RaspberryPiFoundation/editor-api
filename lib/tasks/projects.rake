# frozen_string_literal: true
require 'yaml'

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    
    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir_name|
      config = YAML.load(File.open("#{File.dirname(__FILE__)}/project_components/#{dir_name}/project_config.yml").read)
      Project.find_by( identifier: config["IDENTIFIER"] )&.destroy
      new_project = Project.new(identifier: config["IDENTIFIER"], name: config["NAME"])
      num_extra_components = 0

      Dir.each_child("#{File.dirname(__FILE__)}/project_components/#{dir_name}") do |component|
        if component != "project_config.yml"
          file = File.open(File.dirname(__FILE__) + "/project_components/#{dir_name}/#{component}")
          component_code = file.read
          file.close
          component_name = component.split('.')[0]
          component_extension = component.split('.').drop(1).join('.')
          if component == "main.py"
            component_index = 0
          else
            num_extra_components += 1
            component_index = num_extra_components
          end
          new_component = Component.new( name: component_name, extension: component_extension, content: component_code, index: component_index )
          new_project.components << new_component 
        end
      end
      new_project.save
    end
  end
end
