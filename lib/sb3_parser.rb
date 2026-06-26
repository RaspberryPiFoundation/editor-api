# frozen_string_literal: true

require 'json'
require 'marcel'
require 'stringio'
require 'zip'

class Sb3Parser
  class MissingProjectJsonError < StandardError; end
  class MissingAssetError < StandardError; end

  attr_reader :component, :file_path, :io

  def initialize(component: nil, file_path: nil)
    @component = component
    @file_path = component&.fetch(:file_path, nil) || file_path
    @io = component&.fetch(:io, nil)
  end

  def parse
    open_zip do |zip_file|
      project_json = project_json_entry(zip_file)
      content = JSON.parse(project_json.get_input_stream.read)

      output = {
        scratch_component: { content: },
        assets: assets(zip_file, extract_asset_names(content))
      }
      output
    end
  end

  private

  def open_zip(&)
    return Zip::File.open(file_path, &) if file_path

    io.rewind if io.respond_to?(:rewind)
    Zip::File.open_buffer(io.read) do |zip_file|
      return yield zip_file
    end
  end

  def project_json_entry(zip_file)
    zip_file.find_entry('project.json') || raise(MissingProjectJsonError, 'project.json not found in SB3 archive')
  end

  def extract_asset_names(value)
    case value
    when Hash
      names = []
      names << value['md5ext'] if value['md5ext'].is_a?(String)
      value.each_value { |item| names.concat(extract_asset_names(item)) }
      names.uniq
    when Array
      value.flat_map { |item| extract_asset_names(item) }.uniq
    else
      []
    end
  end

  def assets(zip_file, asset_names)
    asset_names.map do |asset_name|
      entry = zip_file.find_entry(asset_name) || raise(MissingAssetError, "asset #{asset_name} not found in SB3 archive")
      asset(entry)
    end
  end

  def asset(entry)
    io = StringIO.new(entry.get_input_stream.read)
    content_type = Marcel::MimeType.for(io, name: entry.name)
    io.rewind

    { filename: entry.name, io:, content_type: }
  end
end
