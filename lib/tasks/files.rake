# frozen_string_literal: true

require 'aws-sdk-s3'

namespace :files do
  desc 'Update CDN files'
  task update: :environment do
    bucket_name = 'editor-images-test'
    s3_client = Aws::S3::Client.new

    s3_client.list_objects(bucket: bucket_name).contents.each do |file|
      s3_client.delete_object(bucket: bucket_name, key: file.key)
    end

    Dir.chdir("#{File.dirname(__FILE__)}/server_files")
    files = Dir.glob('**/*').select { |f| File.file? f }
    files.each do |file_name|
      s3_client.put_object(
        body: File.open("#{File.dirname(__FILE__)}/server_files/#{file_name}"),
        bucket: bucket_name,
        key: file_name
      )
    end
  end
end
