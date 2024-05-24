# frozen_string_literal: true

require 'cancan/matchers'
require 'rails_helper'

RSpec.describe Ability do
  subject { described_class.new(user) }

  let(:user_id) { SecureRandom.uuid }
  let(:project) { build(:project, user_id:) }
  let(:starter_project) { build(:project, user_id: nil) }

  describe 'Project' do
    context 'when no user' do
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

    context 'when user present' do
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
  end

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
        user.organisations = { school.id => 'school-owner' }
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.to be_able_to(:update, school) }
      it { is_expected.to be_able_to(:destroy, school) }
    end

    context 'when user is a school teacher' do
      before do
        user.organisations = { school.id => 'school-teacher' }
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.not_to be_able_to(:update, school) }
      it { is_expected.not_to be_able_to(:destroy, school) }
    end

    context 'when user is a school student' do
      before do
        user.organisations = { school.id => 'school-student' }
      end

      it { is_expected.to be_able_to(:read, school) }
      it { is_expected.not_to be_able_to(:update, school) }
      it { is_expected.not_to be_able_to(:destroy, school) }
    end
  end
end
