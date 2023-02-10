# frozen_string_literal: true

require 'yaml'

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    code_formats = [".py", '.csv', '.txt']
    image_formats = ['.png', '.jpg', '.jpeg']

    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir|
      proj_config = YAML.safe_load(File.read("#{File.dirname(__FILE__)}/project_components/#{dir}/project_config.yml"))
      project = find_project(proj_config)
      files = Dir.children("#{File.dirname(__FILE__)}/project_components/#{dir}")
      code_files = files.filter{ |file| code_formats.include? File.extname(file) }
      image_files = files.filter{ |file| image_formats.include? File.extname(file) }

      code_files.each do |file|
          name = File.basename(file, '.*')
          extension = File.extname(file).delete('.')
          code = File.read(File.dirname(__FILE__) + "/project_components/#{dir}/#{File.basename(file)}")
          default = (File.basename(file)=='main.py')
          project_component = Component.new(name:, extension:, content: code, default:)
          project.components << project_component
      end
      delete_removed_images(project, image_files)
      image_files.each do |image| 
        attach_image_if_needed(project, image, dir)
      end

      # project_images = proj_config['IMAGES'] || []
      # delete_removed_images(project, project_images)
      # project_images.each do |image_name|
      #   attach_image_if_needed(project, image_name, dir)
      # end
      # puts project.identifier
      # puts project.components.length
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
  new_image_names = images_to_attach.map { |image| File.basename(image) }
  existing_image_names = project.images.map { |x| x.blob.filename.to_s }
  diff = existing_image_names - new_image_names
  return if diff.empty?

  diff.each do |filename|
    img = project.images.find { |i| i.blob.filename == filename }
    img.purge
  end
end

def attach_image_if_needed(project, image, dir)
  image_name = File.basename(image)
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
