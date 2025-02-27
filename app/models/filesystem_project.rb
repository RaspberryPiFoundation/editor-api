# frozen_string_literal: true

require 'yaml'

class FilesystemProject
  CODE_FORMATS = ['.py', '.csv', '.txt', '.html', '.css'].freeze
  PROJECTS_ROOT = Rails.root.join('lib/tasks/project_components')
  PROJECT_CONFIG = 'project_config.yml'

  def self.import_all!
    PROJECTS_ROOT.each_child do |dir|
      proj_config = YAML.safe_load_file(dir.join(PROJECT_CONFIG).to_s)

      files = dir.children.reject { |file| file.basename.to_s == 'project_config.yml' }
      categorized_files = categorize_files(files, dir)

      project_importer = ProjectImporter.new(name: proj_config['NAME'], identifier: proj_config['IDENTIFIER'],
                                             type: proj_config['TYPE'] || Project::Types::PYTHON,
                                             locale: proj_config['LOCALE'] || 'en', **categorized_files)
      project_importer.import!
    end
  end

  def self.categorize_files(files, dir)
    categories = {
      components: [],
      images: [],
      videos: [],
      audio: []
    }

    files.each do |file|
      if CODE_FORMATS.include? File.extname(file)
        categories[:components] << component(file, dir)
      else
        mime_type = file_mime_type(file)

        case mime_type
        when %r{text|application/javascript}
          categories[:components] << component(file, dir)
        when /image/
          categories[:images] << media(file, dir)
        when /video/
          categories[:videos] << media(file, dir)
        when /audio/
          categories[:audio] << media(file, dir)
        else
          raise "Unsupported file type: #{mime_type}"
        end
      end
    end

    categories
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
