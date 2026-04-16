# frozen_string_literal: true

class ScratchAsset < ApplicationRecord
  belongs_to :project, optional: true
  has_one_attached :file

  validates :filename, presence: true, uniqueness: { scope: %i[project_id uploaded_user_id] }
  validates :uploaded_user_id, absence: true, if: :global?
  validates :uploaded_user_id, presence: true, unless: :global?
  validate :belongs_to_scratch_project

  scope :global_assets, -> { where(project_id: nil, uploaded_user_id: nil) }

  def self.find_visible_to_project(project:, user:, filename:)
    lineage_projects = project.self_and_ancestors
    current_user_id = user&.id
    assets_by_project_id = includes(:file_attachment)
                           .where(filename:, project_id: lineage_projects.map(&:id))
                           .group_by(&:project_id)

    lineage_projects.each do |lineage_project|
      project_assets = assets_by_project_id.fetch(lineage_project.id, [])
      visible_asset = [current_user_id, lineage_project.user_id].compact.uniq.find_map do |uploaded_user_id|
        project_assets.find { |asset| asset.uploaded_user_id == uploaded_user_id }
      end
      return visible_asset if visible_asset
    end

    global_assets.includes(:file_attachment).find_by(filename:)
  end

  def global?
    project_id.nil?
  end

  def response_content_type
    extension_is_svg = File.extname(filename).casecmp('.svg').zero?
    return 'image/svg+xml' if global? && extension_is_svg
    return 'application/octet-stream' if extension_is_svg

    file.content_type.presence || 'application/octet-stream'
  end

  private

  def belongs_to_scratch_project
    return if project.blank? || project.scratch_project?

    errors.add(:project, 'must be a Scratch project')
  end
end
