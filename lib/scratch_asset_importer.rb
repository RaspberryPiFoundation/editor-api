# frozen_string_literal: true

require 'ruby-progressbar'
require 'stringio'
require 'aws-sdk-s3'

class ScratchAssetImporter
  class << self
    def import_all(asset_names, asset_base_url)
      bar = ProgressBar.create(format: '%t: |%B| %c of %C %E', total: asset_names.count) if show_progress?

      asset_names.each do |asset_name|
        bar.increment if show_progress?
        new(asset_name, asset_base_url).import
      end
    end

    private

    def show_progress?
      !Rails.env.test?
    end
  end

  attr_reader :asset_base_url, :asset_name

  ASSET_FETCHING_DELAY = 0.2

  def initialize(asset_name, asset_base_url)
    @asset_name = asset_name
    @asset_base_url = asset_base_url
  end

  def import
    return if ScratchAsset.global_assets.exists?(filename: asset_name)

    sleep(ASSET_FETCHING_DELAY)
    asset = connection.get("#{asset_name}/get/")
    ScratchAsset.create!(filename: asset_name, project_id: nil, uploaded_user_id: nil)
                .file
                .attach(io: StringIO.new(asset.body), filename: asset_name)
  rescue StandardError => e
    Rails.logger.error("Failed to import asset #{asset_name}: #{e.message}")
  end

  def connection
    @connection ||= Faraday.new(url: asset_base_url) do |faraday|
      faraday.response :raise_error
    end
  end
end
