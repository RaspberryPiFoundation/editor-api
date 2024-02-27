# frozen_string_literal: true

json.call(@project)

json.image_list @project.images do |image|
  json.filename image.filename
  json.url rails_blob_url(image)
  json.blob_data Base64.strict_encode64(image.blob.download)
  json.content_type image.blob.content_type
end
