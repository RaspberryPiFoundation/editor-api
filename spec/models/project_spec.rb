# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:components) }
  end

  describe 'identifier not nil' do
    it 'generates an identifier if not present' do
      proj = build(:project, identifier: nil)
      expect { proj.valid? }
        .to change { proj.identifier.nil? }
        .from(true)
        .to(false)
    end
  end

  describe 'identifier unique' do
    it do
      project1 = create(:project)
      project2 = build(:project, identifier: project1.identifier)
      expect { project2.valid? }.to change(project2, :identifier)
    end
  end

  describe 'relationship between parent and child projects' do
    before(:each) do
      @project1 = create(:project)
      remix_params = { phrase_id: @project1.identifier, remix: { user_id: SecureRandom.uuid } }
      @project2 = Project::Operation::CreateRemix.call(remix_params)[:project]
      @project3 = Project::Operation::CreateRemix.call(remix_params)[:project]
    end

    it 'child can access parent project' do
      expect(@project2.parent).to eq(@project1)
    end

    it 'parent can access child projects' do
      expect(@project1.children).to eq([@project2])
    end
  end
end
