# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation UpdateComponent() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) { 'mutation UpdateComponent($component: UpdateComponentInput!) { updateComponent(input: $component) { component { id } } }' }
  let(:component_id) { 'dummy-id' }
  let(:variables) do
    {
      component: {
        id: component_id,
        name: 'main2',
        extension: 'py',
        content: '',
        default: false
      }
    }
  end

  shared_examples 'a no-op' do |error_code: 'UNSET'|
    it 'does not update the component' do
      expect { result }.not_to change { component.reload.name }
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'extensions', 'code')).to eq error_code
    end
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'with an existing component' do
    let(:component) { create(:component, name: 'bob', extension: 'html', content: 'new', default: true) }
    let(:component_id) { component.to_gid_param }

    before do
      # Instantiate component
      component
    end

    context 'when unauthenticated' do
      it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
    end

    context 'when the graphql context is unset' do
      let(:graphql_context) { nil }

      it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
    end

    context 'when authenticated' do
      let(:current_user_id) { component.project.user_id }

      it 'updates the component name' do
        expect { result }.to change { component.reload.name }.from(component.name).to(variables.dig(:component, :name))
      end

      it 'updates the component content' do
        expect { result }.to change { component.reload.content }.from(component.content).to(variables.dig(:component, :content))
      end

      it 'updates the component extension' do
        expect { result }.to change { component.reload.extension }.from(component.extension).to(variables.dig(:component, :extension))
      end

      it 'updates the component default' do
        expect { result }.to change { component.reload.default }.from(component.default).to(variables.dig(:component, :default))
      end

      context 'when the user is not allowed to update components' do
        before do
          ability = instance_double(Ability, can?: false)
          allow(Ability).to receive(:new).and_return(ability)
        end

        it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
      end

      context 'when the component cannot be found' do
        let(:component_id) { 'dummy' }

        it_behaves_like 'a no-op', error_code: 'NOT_FOUND'
      end

      context 'with another users component' do
        let(:current_user_id) { SecureRandom.uuid }

        it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
      end

      context 'when component update fails' do
        before do
          errors = instance_double(ActiveModel::Errors, full_messages: ['An error message'])
          allow(component).to receive(:save).and_return(false)
          allow(component).to receive(:errors).and_return(errors)
          allow(GlobalID).to receive(:find).and_return(component)
        end

        it 'returns an error' do
          expect(result.dig('errors', 0, 'message')).to match(/An error message/)
        end
      end
    end
  end
end
