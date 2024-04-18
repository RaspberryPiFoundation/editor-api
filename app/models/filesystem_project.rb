# frozen_string_literal: true

require 'yaml'

class FilesystemProject
  CODE_FORMATS = ['.py', '.csv', '.txt', '.html', '.css'].freeze
  IMAGE_FORMATS = ['.png', '.jpg', '.jpeg', '.webp'].freeze
  PROJECTS_ROOT = Rails.root.join('lib/tasks/project_components')

  def self.import_all! # rubocop:disable Metrics/AbcSize
    PROJECTS_ROOT.each_child do |dir|
      proj_config = YAML.safe_load_file(dir.join('project_config.yml').to_s)
      files = dir.children
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
                                             type: proj_config['TYPE'] || 'python',
                                             locale: proj_config['LOCALE'] || 'en', components:, images:)
      project_importer.import!
    end
  end

  def self.component(file, dir)
    name = File.basename(file, '.*')
    extension = File.extname(file).delete('.')
    code = File.read(dir.join(File.basename(file)).to_s)
    default = (File.basename(file) == 'main.py')
    component = { name:, extension:, content: code, default: }
  end

  def self.image(file, dir)
    filename = File.basename(file)
    io = File.open(dir.join(filename).to_s)
    image = { filename:, io: }
  end
end
