# frozen_string_literal: true

class Component < ApplicationRecord
  belongs_to :project
  validates :name, presence: true
  validates :extension, presence: true
  validates :content, length: { maximum: 8_500_000 }
  validate :default_component_protected_properties, on: :update

  has_paper_trail(
    if: ->(c) { c.project&.school_id },
    meta: {
      meta_project_id: ->(c) { c.project&.id },
      meta_school_id: ->(c) { c.project&.school_id }
    }
  )

  private

  def default_component_protected_properties
    return unless default?

    errors.add(:name, I18n.t('errors.project.editing.change_default_name')) if name_changed?
    errors.add(:extension, I18n.t('errors.project.editing.change_default_extension')) if extension_changed?
  end
end
