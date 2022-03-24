# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name, :user_id)

json.parent(@project.parent, :name, :identifier) if @project.parent

json.components @project.components, :id, :name, :extension, :content, :index

json.image_list @project.images do |image|
  json.filename image.filename
  json.url rails_blob_url(image)
end
