# frozen_string_literal: true

json.array! @projects, :identifier, :project_type, :name, :user_id
