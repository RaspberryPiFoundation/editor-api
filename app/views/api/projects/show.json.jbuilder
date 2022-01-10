json.(@project, :identifier, :project_type, :name)

json.components @project.components, :id, :name, :extension, :content
