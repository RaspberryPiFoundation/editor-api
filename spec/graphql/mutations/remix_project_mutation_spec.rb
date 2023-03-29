# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mutation RemixProject() { ... }' do
  subject(:result) { execute_query(query: mutation, variables:) }

  let(:mutation) do
    'mutation RemixProject($id: String!, $name: String, $components: [ProjectComponentInput!]) {
    remixProject(input: { id: $id, name: $name, components: $components }) {
      project {
        id
      }
    }
  }
  '
  end
  let!(:project) { create(:project, :with_default_component, user_id: SecureRandom.uuid) }
  let(:project_id) { project.to_gid_param }
  let(:variables) { { id: project_id } }

  shared_examples 'a no-op' do |error_code: 'UNSET'|
    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end

    it 'returns an error' do
      expect(result.dig('errors', 0, 'extensions', 'code')).to eq error_code
    end
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'when unauthenticated' do
    let(:current_user_id) { nil }

    it_behaves_like 'a no-op', error_code: 'UNAUTHORIZED'
  end

  context 'when original project not found' do
    let(:project_id) { SecureRandom.uuid }
    let(:current_user_id) { SecureRandom.uuid }

    it_behaves_like 'a no-op', error_code: 'NOT_FOUND'
  end

  context 'when user cannot view original project' do
    let(:current_user_id) { SecureRandom.uuid }

    it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
  end

  context 'when authenticated but the user is not allowed to remix projects' do
    let(:current_user_id) { SecureRandom.uuid }

    before do
      ability = instance_double(Ability, can?: false)
      allow(Ability).to receive(:new).and_return(ability)
    end

    it_behaves_like 'a no-op', error_code: 'FORBIDDEN'
  end

  context 'when authenticated and project exists' do
    let(:current_user_id) { project.user_id }
    let(:returned_gid) { result.dig('data', 'remixProject', 'project', 'id') }
    let(:remixed_project) { GlobalID.find(returned_gid) }

    it 'creates a project' do
      expect { result }.to change(Project, :count).by(1)
    end

    it 'returns graphql id for remixed project' do
      expect(returned_gid).to eq Project.order(created_at: :asc).last.to_gid_param
    end

    context 'when name and components not specified' do
      it 'uses original project name' do
        expect(remixed_project.name).to eq(project.name)
      end

      it 'uses original project components' do
        expect(remixed_project.components[0].content).to eq(project.components[0].content)
      end
    end

    context 'when name and components specified' do
      before do
        variables[:name] = 'My amazing remix'
        variables[:components] = [
          {
            name: 'main',
            extension: 'py',
            default: true,
            content: "print('this is amazing')"
          }
        ]
      end

      it 'updates remixed project name if given' do
        expect(remixed_project.name).to eq(variables[:name])
      end

      it 'updates remixed project components if given' do
        expect(remixed_project.components[0].content).to eq(variables[:components][0][:content])
      end
    end

    context 'when project creation fails' do
      before do
        allow(Project::CreateRemix).to receive(:call).and_return(OperationResponse[error: 'Something went wrong'])
      end

      it 'returns an error' do
        expect(result.dig('errors', 0, 'message')).to eq 'Something went wrong'
      end
    end
  end
end
