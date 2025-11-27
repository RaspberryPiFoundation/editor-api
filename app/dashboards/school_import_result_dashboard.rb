# frozen_string_literal: true

require 'administrate/base_dashboard'

class SchoolImportResultDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String,
    job_id: StatusField,
    user_id: UserInfoField,
    results: ResultsSummaryField,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    job_id
    user_id
    results
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    job_id
    user_id
    results
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(school_import_result)
    "Import Job #{school_import_result.job_id}"
  end
end
