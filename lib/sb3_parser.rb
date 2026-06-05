# frozen_string_literal: true

require 'json'
require 'marcel'
require 'stringio'
require 'zip'

class Sb3Parser
  class MissingProjectJsonError < StandardError; end
  class MissingAssetError < StandardError; end

  attr_reader :file_path

  def initialize(file_path:)
    @file_path = file_path
  end

  def parse
    Zip::File.open(file_path) do |zip_file|
      project_json = project_json_entry(zip_file)
      content = JSON.parse(project_json.get_input_stream.read)

      output = {
        scratch_component: { content: }
        # assets: assets(zip_file, extract_asset_names(content))
      }
      pp output
      output
    end
  end

  private

  def project_json_entry(zip_file)
    zip_file.find_entry('project.json') || raise(MissingProjectJsonError, 'project.json not found in SB3 archive')
  end

  # def extract_asset_names(value)
  #   case value
  #   when Hash
  #     names = []
  #     names << value['md5ext'] if value['md5ext'].is_a?(String)
  #     value.each_value { |item| names.concat(extract_asset_names(item)) }
  #     names.uniq
  #   when Array
  #     value.flat_map { |item| extract_asset_names(item) }.uniq
  #   else
  #     []
  #   end
  # end

  # def assets(zip_file, asset_names)
  #   entries_by_name = zip_file.each.reject(&:directory?).index_by { |entry| entry.name }

  #   asset_names.map do |asset_name|
  #     entry = entries_by_name[asset_name] || raise(MissingAssetError, "asset #{asset_name} not found in SB3 archive")
  #     asset(entry)
  #   end
  # end

  # def asset(entry)
  #   io = StringIO.new(entry.get_input_stream.read)
  #   content_type = Marcel::MimeType.for(io, name: entry.name)
  #   io.rewind

  #   { filename: entry.name, io:, content_type: }
  # end
end
