module Admin::ProjectHelper
  def projects_link(search_term, scope = nil)
    params = {}.tap do |hsh|
      hsh[:search] = search_term if search_term.present?
      hsh[:scope] = scope if scope.present?
    end
    admin_projects_path(params)
  end

  def sanitized_project_order_params
    params.permit(:search, :id, :order, :page, :per_page, :direction, :orders, :scope)
  end
end
