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

  def self.import_from_sb3_assets(assets, asset_base_url)
    new(nil, asset_base_url).import_from_sb3_assets(assets)
  end

  attr_reader :asset_base_url, :asset_names

  ASSET_FETCHING_DELAY = 0.2

  def initialize(asset_name, asset_base_url)
    @asset_name = asset_name
    @asset_base_url = asset_base_url
  end

  def import
    create_scratch_asset
    save_to_editor_asset_bucket
  rescue Faraday::Error => e
    Rails.logger.error("Failed to import asset #{asset_name}: #{e.message}")
  end

  def asset
    @asset ||= begin
      sleep(ASSET_FETCHING_DELAY)
      connection.get("#{asset_name}/get/")
    end
  end

  def import_from_sb3_assets(assets)
    bar = ProgressBar.create(format: '%t: |%B| %c of %C %E', total: assets.count) if show_progress?

    assets.each do |asset|
      bar.increment if show_progress?
      import_sb3_asset(asset.fetch(:filename), asset.fetch(:io).read)
    end
  end

  private

  def create_scratch_asset(asset_names)
    return if ScratchAsset.global_assets.exists?(filename: asset_name)

    io = StringIO.new(asset.body)

    ScratchAsset.create!(filename: asset_name, project_id: nil, uploaded_user_id: nil)
                .file
                .attach(io:, filename: asset_name)
  end

  def save_to_editor_asset_bucket
    return unless save_to_editor_asset_bucket?

    body = StringIO.new(asset.body)

    s3_client.put_object(
      bucket: ENV.fetch('EDITOR_ASSETS_BUCKET'),
      key: asset_key,
      body:,
      content_type: asset_content_type,
      cache_control: 'public, max-age=604800'
    )
  end

  def save_to_editor_asset_bucket?
    return false unless ENV['EDITOR_ASSETS_BUCKET']

    s3_client.head_object(bucket: ENV.fetch('EDITOR_ASSETS_BUCKET'), key: asset_key)
    false
  rescue Aws::S3::Errors::NotFound
    true
  end

  def asset_key
    "internalapi/asset/#{asset_name}/get/"
  end

  def asset_content_type
    extension = File.extname(asset_name).delete('.')
    mime_type = Mime::Type.lookup_by_extension(extension)
    raise "Unknown content type for extension: #{extension}" unless mime_type

    mime_type.to_s
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: ENV.fetch('EDITOR_ASSETS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('EDITOR_ASSETS_SECRET_ACCESS_KEY'),
      endpoint: ENV.fetch('EDITOR_ASSETS_ENDPOINT'),
      region: 'auto'
    )
  end

  def import_sb3_asset(asset_name, content)
    return if ScratchAsset.global_assets.exists?(filename: asset_name)

    sleep(ASSET_FETCHING_DELAY)
    ScratchAsset.create!(filename: asset_name, project_id: nil, uploaded_user_id: nil)
                .file
                .attach(io: StringIO.new(content), filename: asset_name)
  rescue StandardError => e
    Rails.logger.error("Failed to import SB3 asset #{asset_name}: #{e.message}")
  end

  def connection
    @connection ||= Faraday.new(url: asset_base_url) do |faraday|
      faraday.response :raise_error
    end
  end
end
