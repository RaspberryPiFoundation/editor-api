# frozen_string_literal: true

class ScratchConfigImporter
  def self.import(...)
    new(...).import
  end

  attr_reader :asset_base_url, :asset_config_url

  def initialize(asset_config_url, asset_base_url)
    @asset_config_url = asset_config_url
    @asset_base_url = asset_base_url
  end

  def import
    config = connection.get.body
    asset_config = JSON.parse(config, symbolize_names: true)
    asset_names = extract_asset_names(asset_config)
    ScratchAssetImporter.import_all(asset_names, asset_base_url)
  end

  def connection
    Faraday.new(url: asset_config_url) do |faraday|
      faraday.response :raise_error
    end
  end

  private

  def extract_asset_names(config)
    names = []
    config.each do |item|
      names << item[:md5ext] if item[:md5ext]
      names.concat(extract_asset_names(item.fetch(:costumes, [])))
      names.concat(extract_asset_names(item.fetch(:sounds, [])))
    end
    names
  end
end
