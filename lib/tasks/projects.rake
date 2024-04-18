# frozen_string_literal: true

namespace :projects do
  desc 'Import starter projects'
  task create_starter: :environment do
    FilesystemProject.import_all!
  end
end
