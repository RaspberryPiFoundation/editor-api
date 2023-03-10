# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation CreateComponent() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) { 'mutation CreateComponent($component: CreateComponentInput!) { createComponent(input: $component) { component { id } } }' }
  let(:project_id) { 'dummy-id' }
  let(:variables) do
    {
      component: {
        projectId: project_id,
        name:"test",
        extension:"py",
        content:"blah",
        default:false
      }
    }
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'when unauthenticated' do
    it 'does not create a component' do
      expect { result }.not_to change(Component, :count)
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'message')).not_to be_blank
    end
  end

  context 'when the graphql context is unset' do
    let(:graphql_context) { nil }

    it 'does not create a component' do
      expect { result }.not_to change(Component, :count)
    end
  end

  context 'when authenticated' do
    userid = SecureRandom.uuid
    let(:current_user_id) { userid }
    let!(:project) { create(:project, user_id: userid) }
    let(:project_id) { project.to_gid_param }

    before { mock_phrase_generation }

    it 'returns the component ID' do
      expect(result.dig('data', 'createComponent', 'component', 'id')).not_to be_nil 
    end

  end
end
