# frozen_string_literal: true

json.array! @paginated_projects, :identifier, :project_type, :name, :user_id, :updated_at
