# frozen_string_literal: true

require 'administrate/base_dashboard'

class SchoolDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::String,
    creator: Field::BelongsTo.with_options(class_name: 'User'),
    name: Field::String,
    website: Field::String,
    address_line_1: Field::String,
    address_line_2: Field::String,
    municipality: Field::String,
    administrative_area: Field::String,
    country_code: CountryField,
    classes: Field::HasMany,
    lessons: Field::HasMany,
    projects: Field::HasMany,
    reference: Field::String,
    verified_at: Field::DateTime,
    rejected_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    name
    reference
    country_code
    verified_at
    rejected_at
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    name
    verified_at
    rejected_at
    creator
    reference
    website
    address_line_1
    address_line_2
    municipality
    administrative_area
    country_code
    classes
    lessons
    projects
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    name
    reference
    website
    address_line_1
    address_line_2
    municipality
    administrative_area
    country_code
  ].freeze

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how projects are displayed
  # across all pages of the admin dashboard.
  #
  def display_resource(school)
    school.name.to_s
  end
end
