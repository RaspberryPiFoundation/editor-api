# frozen_string_literal: true

class Component < ApplicationRecord
  belongs_to :project
  validates :name, presence: true
  validates :extension, presence: true
  validates :index, presence: true, uniqueness: { scope: :project_id }
  validate :default_component_protected_properties, on: :update

  private

  def default_component_protected_properties
    return unless default?

    errors.add(:name, I18n.t('errors.project.editing.change_default_name')) if name_changed?
    errors.add(:extension, I18n.t('errors.project.editing.change_default_extension')) if extension_changed?
  end
end
