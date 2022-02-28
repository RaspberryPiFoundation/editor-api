# frozen_string_literal: true

json.call(@project, :identifier, :project_type, :name)

if (@project.parent) 
    json.parent(@project.parent, :name, :identifier)
end

json.components @project.components, :id, :name, :extension, :content
