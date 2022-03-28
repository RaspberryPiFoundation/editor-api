# frozen_string_literal: true

require 'yaml'

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir|
      proj_config = YAML.safe_load(File.read("#{File.dirname(__FILE__)}/project_components/#{dir}/project_config.yml"))
      Project.find_by(identifier: proj_config['IDENTIFIER'])&.destroy
      new_project = Project.new(identifier: proj_config['IDENTIFIER'], name: proj_config['NAME'])
      components = proj_config['COMPONENTS']
      components.each do |component|
        name = component['name']
        extension = component['extension']
        code = File.read(File.dirname(__FILE__) + "/project_components/#{dir}/#{component['location']}")
        index = component['index']
        default = component['default']
        project_component = Component.new(name: name, extension: extension, content: code, index: index,
                                          default: default)
        new_project.components << project_component
      end

      project_images = proj_config['IMAGES'] || []
      project_images.each do |image_name|
        new_project.images.attach(io: File.open(File.dirname(__FILE__) + "/project_components/#{dir}/#{image_name}"),
                                  filename: image_name)
      end

      new_project.save
    end
  end
end
