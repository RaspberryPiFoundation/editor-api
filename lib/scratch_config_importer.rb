require 'ruby-progressbar'

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
    config = Faraday.get(asset_config_url).body
    asset_config = JSON.parse(config, symbolize_names: true)
    asset_names = extract_asset_names(asset_config)
    ScratchAssetImporter.import(asset_names, asset_base_url)
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
