# frozen_string_literal: true

require 'aws-sdk-s3'

namespace :files do
  desc 'Update CDN files'
  task update: :environment do
    s3_client = Aws::S3::Client.new
    file_names = s3_client.list_objects(bucket: 'editor-images-test').contents.map(&:key)
    puts(file_names)

    Dir.each_child("#{File.dirname(__FILE__)}/server_files/") do |file_name|
      s3_client.put_object(
        body: File.open(File.dirname(__FILE__) + "/server_files/#{file_name}"),
        bucket: 'editor-images-test',
        key: file_name
      )
    end
  end
end
