# frozen_string_literal: true

require 'yaml'

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir|
      proj_config = YAML.safe_load(File.read("#{File.dirname(__FILE__)}/project_components/#{dir}/project_config.yml"))
      project = find_project(proj_config)
      components = proj_config['COMPONENTS']
      components.each do |component|
        name = component['name']
        extension = component['extension']
        code = File.read(File.dirname(__FILE__) + "/project_components/#{dir}/#{component['location']}")
        index = component['index']
        default = component['default']
        project_component = Component.new(name:, extension:, content: code, index:, default:)
        project.components << project_component
      end

      project_images = proj_config['IMAGES'] || []
      delete_removed_images(project, project_images)
      project_images.each do |image_name|
        attach_image_if_needed(project, image_name, dir)
      end

      project.save
    end
  end
end

def find_project(proj_config)
  if Project.find_by(identifier: proj_config['IDENTIFIER']).nil?
    project = Project.new(identifier: proj_config['IDENTIFIER'], name: proj_config['NAME'],
                          project_type: proj_config['TYPE'] ||= 'python')
  else
    project = Project.find_by(identifier: proj_config['IDENTIFIER'])
    project.name = proj_config['NAME']
    project.components.each(&:destroy)
  end

  project
end

def delete_removed_images(project, images_to_attach)
  existing_images = project.images.map { |x| x.blob.filename.to_s }
  diff = existing_images - images_to_attach
  return if diff.empty?

  diff.each do |filename|
    img = project.images.find { |i| i.blob.filename == filename }
    img.purge
  end
end

def attach_image_if_needed(project, image_name, dir)
  existing_image = project.images.find { |i| i.blob.filename == image_name }

  if existing_image
    return if existing_image.blob.checksum == image_checksum(image_name, dir)

    existing_image.purge
  end
  project.images.attach(io: File.open(File.dirname(__FILE__) + "/project_components/#{dir}/#{image_name}"),
                        filename: image_name)
end

def image_checksum(image_name, dir)
  io = File.open(File.dirname(__FILE__) + "/project_components/#{dir}/#{image_name}")
  OpenSSL::Digest.new('MD5').tap do |checksum|
    while (chunk = io.read(5.megabytes))
      checksum << chunk
    end

    io.rewind
  end.base64digest
end
