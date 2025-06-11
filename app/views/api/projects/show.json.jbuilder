# frozen_string_literal: true

json.call(
  @project,
  :identifier,
  :project_type,
  :locale,
  :name,
  :user_id,
  :instructions
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

json.videos(@project.videos) do |video|
  json.filename(video.filename)
  json.url(rails_blob_url(video))
end

json.audio(@project.audio) do |audio_file|
  json.filename(audio_file.filename)
  json.url(rails_blob_url(audio_file))
end

json.user_name(@user&.name) if @user.present? && @project.parent
