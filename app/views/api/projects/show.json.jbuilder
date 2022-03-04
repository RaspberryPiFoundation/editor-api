# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name, :user_id)

json.parent(@project.parent, :name, :identifier) if @project.parent

json.components @project.components, :id, :name, :extension, :content
