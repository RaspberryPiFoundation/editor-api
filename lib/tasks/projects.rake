# frozen_string_literal: true

namespace :projects do
  desc 'Import starter & example projects'
  task create_all: :environment do
    FilesystemProject.import_all!
  end
end
