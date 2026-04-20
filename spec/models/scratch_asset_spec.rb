# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScratchAsset do
  describe '.find_visible_to_project' do
    let(:filename) { 'costume.png' }
    let(:teacher) { build(:user) }
    let(:student) { build(:user) }
    let(:other_student) { build(:user) }
    let(:teacher_project) { create_scratch_project(user_id: teacher.id) }
    let(:student_remix) { create_scratch_project(user_id: student.id, remixed_from_id: teacher_project.id) }

    it 'returns the closest matching asset in the project lineage' do
      create_scratch_asset(project: teacher_project, uploaded_user_id: teacher.id)
      remix_asset = create_scratch_asset(project: student_remix, uploaded_user_id: student.id)

      expect(described_class.find_visible_to_project(project: student_remix, user: student, filename:)).to eq(remix_asset)
    end

    it 'prefers an asset uploaded by the current user before remixing over the project owner asset' do
      create_scratch_asset(project: teacher_project, uploaded_user_id: teacher.id)
      pending_student_asset = create_scratch_asset(project: teacher_project, uploaded_user_id: student.id)

      expect(described_class.find_visible_to_project(project: teacher_project, user: student, filename:)).to eq(pending_student_asset)
    end

    it 'falls back to an ancestor project owner asset' do
      teacher_asset = create_scratch_asset(project: teacher_project, uploaded_user_id: teacher.id)

      expect(described_class.find_visible_to_project(project: student_remix, user: student, filename:)).to eq(teacher_asset)
    end

    it 'does not return assets uploaded by unrelated users' do
      create_scratch_asset(project: teacher_project, uploaded_user_id: other_student.id)

      expect(described_class.find_visible_to_project(project: teacher_project, user: student, filename:)).to be_nil
    end

    it 'falls back to a global asset when no visible project asset exists' do
      global_asset = create_scratch_asset(project: nil, uploaded_user_id: nil)

      expect(described_class.find_visible_to_project(project: teacher_project, user: student, filename:)).to eq(global_asset)
    end

    def create_scratch_project(user_id:, remixed_from_id: nil)
      create(
        :project,
        user_id:,
        remixed_from_id:,
        project_type: Project::Types::CODE_EDITOR_SCRATCH,
        locale: nil
      )
    end

    def create_scratch_asset(project:, uploaded_user_id:)
      create(:scratch_asset, filename:, project:, uploaded_user_id:)
    end
  end
end
