# frozen_string_literal: true

require 'yaml'
require 'project_importer'

CODE_FORMATS = ['.py', '.csv', '.txt'].freeze
IMAGE_FORMATS = ['.png', '.jpg', '.jpeg'].freeze

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    Dir.each_child("#{File.dirname(__FILE__)}/project_components") do |dir|
      proj_config = YAML.safe_load(File.read("#{File.dirname(__FILE__)}/project_components/#{dir}/project_config.yml"))
      files = Dir.children("#{File.dirname(__FILE__)}/project_components/#{dir}")
      code_files = files.filter { |file| CODE_FORMATS.include? File.extname(file) }
      image_files = files.filter { |file| IMAGE_FORMATS.include? File.extname(file) }

      components = []
      code_files.each do |file|
        components << component(file, dir)
      end

      images = []
      image_files.each do |file|
        images << image(file, dir)
      end

      project_importer = ProjectImporter.new(name: proj_config['NAME'], identifier: proj_config['IDENTIFIER'],
                                             type: proj_config['TYPE'] ||= 'python',
                                             locale: proj_config['LOCALE'] ||= 'en', components:, images:)
      project_importer.import!
    end
  end
end

private

def component(file, dir)
  name = File.basename(file, '.*')
  extension = File.extname(file).delete('.')
  code = File.read(File.dirname(__FILE__) + "/project_components/#{dir}/#{File.basename(file)}")
  default = (File.basename(file) == 'main.py')
  component = { name:, extension:, content: code, default: }
end

def image(file, dir)
  filename = File.basename(file)
  io = File.open(File.dirname(__FILE__) + "/project_components/#{dir}/#{filename}")
  image = { filename:, io: }
end
