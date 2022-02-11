# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name)

json.components @project.components, :id, :name, :extension, :content
