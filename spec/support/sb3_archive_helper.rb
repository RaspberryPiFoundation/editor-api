# frozen_string_literal: true

module Sb3ArchiveHelper
  def sb3_archive(entries)
    Zip::OutputStream.write_buffer do |zip|
      entries.each do |name, content|
        zip.put_next_entry(name)
        zip.write(content)
      end
    end.tap(&:rewind)
  end

  def sb3_archive_string(entries)
    sb3_archive(entries).string
  end

  def sb3_fixture_content(filename)
    Rails.root.join('spec/fixtures/files', filename).binread
  end
end

RSpec.configure do |config|
  config.include Sb3ArchiveHelper
end
