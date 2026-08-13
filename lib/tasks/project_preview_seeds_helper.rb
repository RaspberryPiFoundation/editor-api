# frozen_string_literal: true

module ProjectPreviewSeedsHelper
  # Public Blocks template for Experience CS project preview (unowned, loadable without auth).
  PROJECT_PREVIEW_IDENTIFIER = 'excs-preview-starter'
  PROJECT_PREVIEW_LOCALE = 'en'
  PROJECT_PREVIEW_LOCALE_FR = 'fr-FR'
  PROJECT_PREVIEW_NAME = 'Experience CS Preview Starter'
  PROJECT_PREVIEW_NAME_FR = 'Démo Aperçu Experience CS'
  PROJECT_PREVIEW_CONTENT_PATH = Rails.root.join('lib/tasks/seed_data/excs_preview_starter.json')
  PROJECT_PREVIEW_INSTRUCTIONS_PATH = Rails.root.join('lib/tasks/seed_data/excs_preview_starter_instructions.json')
  PROJECT_PREVIEW_INSTRUCTIONS_FR_PATH = Rails.root.join('lib/tasks/seed_data/excs_preview_starter_instructions_fr.json')

  def create_public_scratch_preview_project
    [
      {
        locale: PROJECT_PREVIEW_LOCALE,
        name: PROJECT_PREVIEW_NAME,
        instructions: public_scratch_preview_instructions
      },
      {
        locale: PROJECT_PREVIEW_LOCALE_FR,
        name: PROJECT_PREVIEW_NAME_FR,
        instructions: public_scratch_preview_instructions_fr
      }
    ].map { |attrs| upsert_public_scratch_preview_project(**attrs) }
  end

  def upsert_public_scratch_preview_project(locale:, name:, instructions:)
    project = Project.find_or_initialize_by(
      identifier: PROJECT_PREVIEW_IDENTIFIER,
      locale:
    )
    raise "Refusing to overwrite non-public project '#{PROJECT_PREVIEW_IDENTIFIER}' (#{locale})" if project.persisted? && (project.user_id.present? || project.school_id.present?)

    Rails.logger.info "Seeding public Scratch preview project '#{PROJECT_PREVIEW_IDENTIFIER}' (#{locale})..."
    project.name = name
    project.user_id = nil
    project.school_id = nil
    project.project_type = Project::Types::CODE_EDITOR_SCRATCH
    project.instructions = instructions
    project.scratch_component ||= ScratchComponent.new
    project.scratch_component.content = public_scratch_preview_content
    project.save!
    project
  end

  def destroy_public_scratch_preview_project
    Project.where(
      identifier: PROJECT_PREVIEW_IDENTIFIER,
      user_id: nil,
      school_id: nil,
      project_type: Project::Types::CODE_EDITOR_SCRATCH
    ).destroy_all
  end

  def public_scratch_preview_content
    JSON.parse(File.read(PROJECT_PREVIEW_CONTENT_PATH))
  end

  def public_scratch_preview_instructions
    JSON.parse(File.read(PROJECT_PREVIEW_INSTRUCTIONS_PATH))
  end

  def public_scratch_preview_instructions_fr
    JSON.parse(File.read(PROJECT_PREVIEW_INSTRUCTIONS_FR_PATH))
  end
end
