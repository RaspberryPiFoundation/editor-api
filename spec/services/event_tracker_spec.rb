# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventTracker do
  describe '.track_project_event!' do
    let(:school) { create(:school) }
    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }
    let(:school_class) { create(:school_class, school:, teacher_ids: [teacher.id]) }
    let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id) }
    let(:teacher_project) { create(:project, school:, lesson:, user_id: teacher.id, locale: nil) }

    it 'tracks required classroom project metadata' do
      described_class.track_project_event!(name: 'Project - Opened', user_id: teacher.id, project: teacher_project)

      expect(Event.last).to have_attributes(
        name: 'Project - Opened',
        user_id: teacher.id,
        properties: {
          'school_id' => school.id,
          'class_id' => school_class.id,
          'lesson_id' => lesson.id,
          'project_type' => Project::Types::PYTHON,
          'user_role' => 'educator'
        },
        time: be_within(1.second).of(Time.current)
      )
    end

    it 'adds a student id for educator interactions with student projects' do
      create(:class_student, school_class:, student_id: student.id)
      student_project = create(:project, school:, parent: teacher_project, user_id: student.id, locale: nil)

      described_class.track_project_event!(name: 'Project - Feedback given', user_id: teacher.id, project: student_project)

      expect(Event.last.properties).to include(
        'student_id' => student.id,
        'user_role' => 'educator'
      )
    end

    it 'does not add a student id for student interactions with their own project' do
      create(:class_student, school_class:, student_id: student.id)
      student_project = create(:project, school:, parent: teacher_project, user_id: student.id, locale: nil)

      described_class.track_project_event!(name: 'Project - Submitted for review', user_id: student.id, project: student_project)

      expect(Event.last.properties).to include('user_role' => 'student')
      expect(Event.last.properties).not_to have_key('student_id')
    end

    it 'does not track project events without full classroom metadata' do
      project = create(:project, user_id: teacher.id, locale: nil)

      expect do
        described_class.track_project_event!(name: 'Project - Saved', user_id: teacher.id, project:)
      end.not_to change(Event, :count)
    end
  end
end
