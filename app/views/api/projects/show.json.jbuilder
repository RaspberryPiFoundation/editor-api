# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name)

json.components @project.components, :id, :name, :extension, :content
json.owned_by_user @project.user_id == @user_id
