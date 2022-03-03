# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name)

json.components @project.components, :id, :name, :extension, :content
json.owned_by_user !@user_id.nil? && @project.user_id == @user_id
