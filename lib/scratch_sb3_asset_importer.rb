# frozen_string_literal: true

require 'stringio'

class ScratchSb3AssetImporter
  class << self
    def import_all(assets)
      assets.each do |asset|
        new.import(asset)
      rescue StandardError
        next
      end
    end
  end

  def import(asset)
    create_asset(asset.fetch(:filename), asset.fetch(:io).read)
  end

  private

  def create_asset(asset_name, content)
    return if ScratchAsset.global_assets.exists?(filename: asset_name)

    ScratchAsset.create!(filename: asset_name, project_id: nil, uploaded_user_id: nil)
                .file
                .attach(io: StringIO.new(content), filename: asset_name)
  end
end
