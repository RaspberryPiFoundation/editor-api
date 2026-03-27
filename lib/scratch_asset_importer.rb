require 'ruby-progressbar'

class ScratchAssetImporter
  def self.import(...)
    new(...).import
  end

  attr_reader :asset_base_url, :asset_names

  def initialize(asset_names, asset_base_url)
    @asset_names = asset_names
    @asset_base_url = asset_base_url
  end

  def import
    asset_names.each do |asset_name|
      import_asset(asset_name)
    end
  end

  private

  def import_asset(asset_name)
    return if ScratchAsset.exists?(filename: asset_name)

    asset = connection.get("#{asset_name}/get/")
    ScratchAsset.create!(filename: asset_name).file.attach(io: StringIO.new(asset.body), filename: asset_name)
  rescue StandardError => e
    Rails.logger.error("Failed to import asset #{asset_name}: #{e.message}")
  end

  def connection
    @connection ||= Faraday.new(url: asset_base_url) do |faraday|
      faraday.response :raise_error
    end
  end
end
