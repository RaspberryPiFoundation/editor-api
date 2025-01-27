# frozen_string_literal: true

require 'yaml'

class FilesystemProject
  CODE_FORMATS = ['.py', '.csv', '.txt', '.html', '.css'].freeze
  # IMAGE_FORMATS = ['.png', '.jpg', '.jpeg', '.webp'].freeze
  PROJECTS_ROOT = Rails.root.join('lib/tasks/project_components')

  def self.import_all!
    PROJECTS_ROOT.each_child do |dir|
      proj_config = YAML.safe_load_file(dir.join('project_config.yml').to_s)
      files = dir.children

      components = []
      images = []
      videos = []
      audio_files = []

      files.each do |file|
        # skip the project_config.yml file
        next if file.basename.to_s == 'project_config.yml'

        mime_type = file_mime_type(file)

        if CODE_FORMATS.include? File.extname(file)
          components << component(file, dir)
        elsif mime_type =~ /image/
          images << media(file, dir)
        elsif mime_type =~ /video/
          videos << media(file, dir)
        elsif mime_type =~ /audio/
          audio_files << media(file, dir)
        else
          raise "File #{File.basename(file)} has unsupported file type: #{mime_type}"
        end
      end

      project_importer = ProjectImporter.new(name: proj_config['NAME'], identifier: proj_config['IDENTIFIER'],
                                             type: proj_config['TYPE'] || 'python',
                                             locale: proj_config['LOCALE'] || 'en', components:, images:, videos:, audio_files:)
      project_importer.import!
    end
  end

  def self.component(file, dir)
    name = File.basename(file, '.*')
    extension = File.extname(file).delete('.')
    code = File.read(dir.join(File.basename(file)).to_s)
    default = (File.basename(file) == 'main.py')
    { name:, extension:, content: code, default: }
  end

  def self.file_mime_type(file)
    Marcel::MimeType.for(File.open(file), name: File.basename(file))
  end

  def self.media(file, dir)
    filename = File.basename(file)
    io = File.open(dir.join(filename).to_s)
    { filename:, io: }
  end
end
