json.(@project, :identifier, :project_type)

json.components @project.components, :id, :name, :extension, :content
