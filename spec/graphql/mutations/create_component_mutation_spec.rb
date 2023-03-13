# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation CreateComponent() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:project) { create(:project) }
  let(:project_id) { project.to_gid_param }

  let(:mutation) { 'mutation CreateComponent($component: CreateComponentInput!) { createComponent(input: $component) { component { id } } }' }
  # let(:project_id) { 'dummy-id' }
  let(:variables) do
    {
      component: {
        projectId: project_id,
        name: 'test',
        extension: 'py',
        content: 'blah',
        default: false
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
    let(:current_user_id) { SecureRandom.uuid }
    let(:project) { create(:project, user_id: current_user_id) }

    it 'returns the component ID' do
      expect(result.dig('data', 'createComponent', 'component', 'id')).not_to be_nil
    end

    context 'when project id doesnt exist' do
      let(:project_id) { 'dummy-id' }

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).not_to be_blank
      end
    end

    context 'when project id exists but belongs to someone else' do
      let(:project) { create(:project) }

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).not_to be_blank
      end
    end

    context 'when project component fails to save' do
      before do
        component = Component.new
        allow(component).to receive(:save).and_return(false)
        allow(Component).to receive(:new).and_return(component)
      end

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).not_to be_nil
      end
    end
  end
end
