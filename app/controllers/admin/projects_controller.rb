module Admin
  class ProjectsController < Admin::ApplicationController
    def scoped_resource
      resource_class.internal_projects
    end
  end
end
