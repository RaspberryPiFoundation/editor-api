# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'lessons', type: :task do
  describe ':backfill_submitted_projects_count' do
    let(:task) { Rake::Task['lessons:backfill_submitted_projects_count'] }
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }
    let(:lesson) { create(:lesson, school:, user_id: teacher.id) }

    before do
      task.reenable
    end

    it 'sets cached submitted project counts for all lessons' do
      submitted_remix = create(:project, school:, remixed_from_id: lesson.project.id, user_id: student.id)
      submitted_remix.school_project.transition_status_to!(:submitted, student.id)

      returned_remix = create(:project, school:, remixed_from_id: lesson.project.id, user_id: student.id)
      returned_remix.school_project.transition_status_to!(:submitted, student.id)
      returned_remix.school_project.transition_status_to!(:returned, teacher.id)

      other_lesson = create(:lesson, school:, user_id: teacher.id, submitted_projects_count: 7)

      lesson.update!(submitted_projects_count: 0)

      task.invoke

      expect(lesson.reload.submitted_projects_count).to eq(1)
      expect(other_lesson.reload.submitted_projects_count).to eq(0)
    end
  end
end
