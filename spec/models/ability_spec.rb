# frozen_string_literal: true

require 'cancan/matchers'
require 'rails_helper'

RSpec.describe Ability do
  subject { described_class.new(user) }

  let(:project) { build(:project) }
  let(:another_project) { build(:project) }
  let(:starter_project) { build(:project, user_id: nil) }

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
    let(:user) { project.user_id }

    context 'with a starter project' do
      it { is_expected.not_to be_able_to(:index, starter_project) }
      it { is_expected.to be_able_to(:show, starter_project) }
      it { is_expected.not_to be_able_to(:create, starter_project) }
      it { is_expected.not_to be_able_to(:update, starter_project) }
      it { is_expected.not_to be_able_to(:destroy, starter_project) }
    end

    context 'with own project' do
      it { is_expected.to be_able_to(:index, project) }
      it { is_expected.to be_able_to(:show, project) }
      it { is_expected.to be_able_to(:create, project) }
      it { is_expected.to be_able_to(:update, project) }
      it { is_expected.to be_able_to(:destroy, project) }
    end

    context 'with another user\'s project' do
      it { is_expected.not_to be_able_to(:index, another_project) }
      it { is_expected.not_to be_able_to(:show, another_project) }
      it { is_expected.not_to be_able_to(:create, another_project) }
      it { is_expected.not_to be_able_to(:update, another_project) }
      it { is_expected.not_to be_able_to(:destroy, another_project) }
    end
  end
end
