# frozen_string_literal: true

project, user = @project_with_user

json.call(
  project,
  :identifier,
  :project_type,
  :locale,
  :name,
  :user_id
)

if @project.parent
  json.parent(
    @project.parent,
    :name,
    :identifier
  )
end

json.components(
  @project.components,
  :id,
  :name,
  :extension,
  :content
)

json.image_list(@project.images) do |image|
  json.filename(image.filename)
  json.url(rails_blob_url(image))
end

json.user_name(user&.name)
