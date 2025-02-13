# frozen_string_literal: true

require 'cancan/matchers'
require 'rails_helper'

RSpec.describe Ability do
  subject { described_class.new(user) }

  let(:user_id) { SecureRandom.uuid }
  let(:project) { build(:project, user_id:) }
  let(:starter_project) { build(:project, user_id: nil) }

  describe 'Project' do
    context 'with no user' do
      let(:user) { nil }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with an owned project' do
        it { is_expected.not_to be_able_to(:index, project) }
        it { is_expected.not_to be_able_to(:show, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.not_to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end
    end

    context 'with a standard user' do
      let(:user) { build(:user, id: user_id) }
      let(:another_project) { build(:project) }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with own project' do
        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.to be_able_to(:create, project) }
        it { is_expected.to be_able_to(:update, project) }
        it { is_expected.to be_able_to(:destroy, project) }
      end

      context 'with another user\'s project' do
        it { is_expected.not_to be_able_to(:read, another_project) }
        it { is_expected.not_to be_able_to(:create, another_project) }
        it { is_expected.not_to be_able_to(:update, another_project) }
        it { is_expected.not_to be_able_to(:destroy, another_project) }
      end
    end

    context 'with a teacher' do
      let(:user) { build(:teacher, id: user_id) }
      let(:another_project) { build(:project) }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with own project' do
        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.to be_able_to(:create, project) }
        it { is_expected.to be_able_to(:update, project) }
        it { is_expected.to be_able_to(:destroy, project) }
      end

      context 'with another user\'s project' do
        it { is_expected.not_to be_able_to(:read, another_project) }
        it { is_expected.not_to be_able_to(:create, another_project) }
        it { is_expected.not_to be_able_to(:update, another_project) }
        it { is_expected.not_to be_able_to(:destroy, another_project) }
      end
    end

    context 'with an owner' do
      let(:user) { build(:owner, id: user_id) }
      let(:another_project) { build(:project) }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with own project' do
        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.to be_able_to(:create, project) }
        it { is_expected.to be_able_to(:update, project) }
        it { is_expected.to be_able_to(:destroy, project) }
      end

      context 'with another user\'s project' do
        it { is_expected.not_to be_able_to(:read, another_project) }
        it { is_expected.not_to be_able_to(:create, another_project) }
        it { is_expected.not_to be_able_to(:update, another_project) }
        it { is_expected.not_to be_able_to(:destroy, another_project) }
      end
    end

    context 'with a student' do
      let(:user) { build(:student, id: user_id) }
      let(:another_project) { build(:project) }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with own project' do
        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.to be_able_to(:create, project) }
        it { is_expected.to be_able_to(:update, project) }
        it { is_expected.to be_able_to(:destroy, project) }
      end

      context 'with another user\'s project' do
        it { is_expected.not_to be_able_to(:read, another_project) }
        it { is_expected.not_to be_able_to(:create, another_project) }
        it { is_expected.not_to be_able_to(:update, another_project) }
        it { is_expected.not_to be_able_to(:destroy, another_project) }
      end
    end

    # rubocop:disable RSpec/MultipleMemoizedHelpers
    context 'with a teachers project where the lesson is visible to students' do
      let(:user) { create(:user) }
      let(:school) { create(:school) }
      let(:teacher) { create(:teacher, school:) }
      let(:school_class) { build(:school_class, school:, teacher_id: teacher.id) }
      let(:lesson) { build(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let!(:project) { build(:project, school:, lesson:, user_id: teacher.id) }

      context 'when user is a school owner' do
        before do
          create(:owner_role, user_id: user.id, school:)
        end

        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.not_to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:set_finished, project.school_project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end

      context 'when user is a school teacher' do
        before do
          create(:teacher_role, user_id: user.id, school:)
        end

        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:set_finished, project.school_project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end

      context 'when user is a school student and belongs to the teachers class' do
        before do
          create(:student_role, user_id: user.id, school:)
          create(:class_member, school_class:, student_id: user.id)
        end

        it { is_expected.to be_able_to(:read, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.not_to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:set_finished, project.school_project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end

      context 'when user is a school student and does not belong to the teachers class' do
        before do
          create(:student_role, user_id: user.id, school:)
        end

        it { is_expected.not_to be_able_to(:read, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.not_to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:set_finished, project.school_project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end
    end

    # TODO: Handle other visibilities

    context 'with a remix of a teachers project' do
      let(:school) { create(:school) }
      let(:student) { create(:student, school:) }
      let(:teacher) { create(:teacher, school:) }
      let(:school_class) { create(:school_class, school:, teacher_id: teacher.id) }
      let(:class_member) { create(:class_member, school_class:, student_id: student.id) }
      let(:lesson) { create(:lesson, school:, school_class:, user_id: teacher.id, visibility: 'students') }
      let(:original_project) { create(:project, school:, lesson:, user_id: teacher.id) }
      let!(:remixed_project) { create(:project, school:, user_id: student.id, remixed_from_id: original_project.id) }

      context 'when user is the student' do
        let(:user) { student }

        it { is_expected.to be_able_to(:read, remixed_project) }
        it { is_expected.to be_able_to(:create, remixed_project) }
        it { is_expected.to be_able_to(:update, remixed_project) }
        it { is_expected.not_to be_able_to(:destroy, remixed_project) }
        it { is_expected.to be_able_to(:set_finished, remixed_project.school_project) }
      end

      context 'when user is teacher that does not own the orginal project' do
        let(:user) { create(:teacher, school:) }

        it { is_expected.not_to be_able_to(:read, remixed_project) }
        it { is_expected.not_to be_able_to(:create, remixed_project) }
        it { is_expected.not_to be_able_to(:update, remixed_project) }
        it { is_expected.not_to be_able_to(:destroy, remixed_project) }
        it { is_expected.not_to be_able_to(:set_finished, remixed_project.school_project) }
      end

      context 'when user is teacher that owns the orginal project' do
        let(:user) { teacher }

        it { is_expected.to be_able_to(:read, remixed_project) }
        it { is_expected.not_to be_able_to(:create, remixed_project) }
        it { is_expected.not_to be_able_to(:update, remixed_project) }
        it { is_expected.not_to be_able_to(:destroy, remixed_project) }
        it { is_expected.not_to be_able_to(:set_finished, remixed_project.school_project) }
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe 'Component' do
    let(:starter_project_component) { build(:component, project: starter_project) }
    let(:component) { build(:component, project:) }

    context 'when no user' do
      let(:user) { nil }

      context 'with a component from a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project_component) }
        it { is_expected.to be_able_to(:show, starter_project_component) }
        it { is_expected.not_to be_able_to(:create, starter_project_component) }
        it { is_expected.not_to be_able_to(:update, starter_project_component) }
        it { is_expected.not_to be_able_to(:destroy, starter_project_component) }
      end

      context 'with a component from an owned project' do
        it { is_expected.not_to be_able_to(:index, component) }
        it { is_expected.not_to be_able_to(:show, component) }
        it { is_expected.not_to be_able_to(:create, component) }
        it { is_expected.not_to be_able_to(:update, component) }
        it { is_expected.not_to be_able_to(:destroy, component) }
      end
    end

    context 'when user present' do
      let(:user) { build(:user, id: user_id) }

      context 'with a component from a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project_component) }
        it { is_expected.to be_able_to(:show, starter_project_component) }
        it { is_expected.not_to be_able_to(:create, starter_project_component) }
        it { is_expected.not_to be_able_to(:update, starter_project_component) }
        it { is_expected.not_to be_able_to(:destroy, starter_project_component) }
      end

      context 'with own project' do
        it { is_expected.to be_able_to(:read, component) }
        it { is_expected.to be_able_to(:create, component) }
        it { is_expected.to be_able_to(:update, component) }
        it { is_expected.to be_able_to(:destroy, component) }
      end

      context 'with another user\'s project' do
        let(:another_project) { build(:project) }
        let(:another_project_component) { build(:component, project: another_project) }

        it { is_expected.not_to be_able_to(:read, another_project_component) }
        it { is_expected.not_to be_able_to(:create, another_project_component) }
        it { is_expected.not_to be_able_to(:update, another_project_component) }
        it { is_expected.not_to be_able_to(:destroy, another_project_component) }
      end
    end
  end

  describe 'School' do
    let(:school) { create(:school) }
    let(:user) { build(:user) }

    context 'when user is not a school-owner but is the creator of the school' do
      before do
        user.id = user_id
        school.update(creator_id: user_id, verified_at: nil)
      end

      it { is_expected.to be_able_to(:read, school) }
    end

    context 'when user is a school owner' do
      before do
        create(:owner_role, user_id: user.id, school:)
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.to be_able_to(:update, school) }
      it { is_expected.to be_able_to(:destroy, school) }
    end

    context 'when user is a school teacher' do
      before do
        create(:teacher_role, user_id: user.id, school:)
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.not_to be_able_to(:update, school) }
      it { is_expected.not_to be_able_to(:destroy, school) }
    end

    context 'when user is a school student' do
      before do
        create(:student_role, user_id: user.id, school:)
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.not_to be_able_to(:update, school) }
      it { is_expected.not_to be_able_to(:destroy, school) }

      context 'with a starter project' do
        it { is_expected.not_to be_able_to(:index, starter_project) }
        it { is_expected.not_to be_able_to(:show, starter_project) }
        it { is_expected.not_to be_able_to(:create, starter_project) }
        it { is_expected.not_to be_able_to(:update, starter_project) }
        it { is_expected.not_to be_able_to(:destroy, starter_project) }
      end

      context 'with an owned project' do
        it { is_expected.not_to be_able_to(:index, project) }
        it { is_expected.not_to be_able_to(:show, project) }
        it { is_expected.not_to be_able_to(:create, project) }
        it { is_expected.not_to be_able_to(:update, project) }
        it { is_expected.not_to be_able_to(:destroy, project) }
      end
    end
  end

  describe 'SchoolMembers' do
    let(:school) { create(:school) }
    let(:owner) { create(:owner, school:) }
    let(:teacher) { create(:teacher, school:) }
    let(:student) { create(:student, school:) }

    context 'when user is a school owner' do
      let(:user) { owner }

      it { is_expected.to be_able_to(:read, :school_member) }
    end

    context 'when user is a school teacher' do
      let(:user) { teacher }

      it { is_expected.to be_able_to(:read, :school_member) }
    end

    context 'when user is a school student' do
      let(:user) { student }

      it { is_expected.not_to be_able_to(:read, :school_member) }
    end

    context 'when user is not authenticated' do
      let(:user) { nil }

      it { is_expected.not_to be_able_to(:read, :school_member) }
    end
  end
end
