require_relative 'seeds_helper'

namespace :scratch_assets do
  desc 'Import scratch assets'
  task import_all: %i[import_backdrops import_costumes import_sounds import_sprites]

  task import_backdrops: :environment do
    Rails.logger.info 'Importing backdrops...'
    config_url = "#{config_base_url}backdrops.json"
    ScratchConfigImporter.import(config_url, import_base_url)
  end

  task import_costumes: :environment do
    Rails.logger.info 'Importing costumes...'
    config_url = "#{config_base_url}costumes.json"
    ScratchConfigImporter.import(config_url, import_base_url)
  end

  task import_sounds: :environment do
    Rails.logger.info 'Importing sounds...'
    config_url = "#{config_base_url}sounds.json"
    ScratchConfigImporter.import(config_url, import_base_url)
  end

  task import_sprites: :environment do
    Rails.logger.info 'Importing sprites...'
    config_url = "#{config_base_url}sprites.json"
    ScratchConfigImporter.import(config_url, import_base_url)
  end

  def config_base_url
    ENV.fetch('SCRATCH_ASSET_CONFIG_BASE_URL')
  end

  def import_base_url
    ENV.fetch('SCRATCH_ASSET_IMPORT_BASE_URL')
  end
end
