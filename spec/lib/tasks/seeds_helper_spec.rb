# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../lib/tasks/seeds_helper'

RSpec.describe SeedsHelper do
  subject(:seeder) { Class.new { include SeedsHelper }.new }

  describe '#create_lessons' do
    let(:teacher_id) { SecureRandom.uuid }
    let(:school) { create(:school) }
    let(:school_class) { create(:school_class, school:, teacher_ids: [teacher_id]) }

    let(:lessons) { seeder.create_lessons(teacher_id, school, school_class) }

    before { create(:teacher_role, user_id: teacher_id, school:) }

    it 'creates a lesson with a Python project' do
      lesson = lessons.find { |l| l.name == 'Lesson 1 python' }

      expect(lesson.project.project_type).to eq(Project::Types::PYTHON)
      component = lesson.project.components.find_by(extension: 'py')
      expect(component.name).to eq('main')
      expect(component.content).to eq('print("Hello World!")')
    end

    it 'creates a lesson with an HTML/CSS project' do
      lesson = lessons.find { |l| l.name == 'Lesson 2 html/css' }

      expect(lesson.project.project_type).to eq(Project::Types::HTML)
      html_component = lesson.project.components.find_by(extension: 'html')
      css_component = lesson.project.components.find_by(extension: 'css')
      expect(html_component.content).to include('<h1>Heading</h1>')
      expect(css_component.content).to include('color: blue')
    end

    it 'creates a lesson with a Scratch project' do
      lesson = lessons.find { |l| l.name == 'Lesson 3 scratch' }

      expect(lesson.project.project_type).to eq(Project::Types::CODE_EDITOR_SCRATCH)
      content = lesson.project.scratch_component.content.to_h
      expect(content).to include('targets', 'monitors', 'extensions')
    end
  end
end
