# frozen_string_literal: true

require 'yaml'

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir|
      project_config = YAML.safe_load(File.open("#{File.dirname(__FILE__)}/project_components/#{dir}/project_config.yml").read)
      Project.find_by(identifier: project_config['IDENTIFIER'])&.destroy
      new_project = Project.new(identifier: project_config['IDENTIFIER'], name: project_config['NAME'])
      components = project_config["COMPONENTS"]
      components.each do |component|
        name = component['name']
        extension = component['extension']
        code = File.read(File.dirname(__FILE__) + "/project_components/#{dir}/#{component['location']}")
        index = component['index']
        project_component = Component.new(name: name, extension: extension, content: code, index: index)
        new_project.components << project_component
      end
      new_project.save
    end
  end
end
