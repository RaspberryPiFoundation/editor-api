# frozen_string_literal: true

json.call(@project)

json.image_list @project.images do |image|
  json.filename image.filename
  json.url rails_blob_url(image)
end