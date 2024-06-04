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
  let(:current_user) { stubbed_user }
  let(:project) { create(:project, :with_default_component, user_id: stubbed_user.id) }
  let(:project_id) { project.to_gid_param }
  let(:variables) { { id: project_id } }
  let(:remix_origin) { 'editor.com' }

  before do
    authenticate_as_school_owner(school_id: create(:school).id)
    project
  end

  it { expect(mutation).to be_a_valid_graphql_query }

  context 'when unauthenticated' do
    let(:current_user) { nil }

    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end

    it 'returns "not permitted to create" error' do
      expect(result.dig('errors', 0, 'message')).to match(/not permitted to create/)
    end
  end

  context 'when original project not found' do
    let(:project_id) { SecureRandom.uuid }

    it 'returns "not found" error' do
      expect(result.dig('errors', 0, 'message')).to match(/not found/)
    end

    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end
  end

  context 'when user cannot view original project' do
    before do
      authenticate_as_school_teacher(school_id: SecureRandom.uuid)
    end

    it 'returns "not permitted to read" error' do
      expect(result.dig('errors', 0, 'message')).to match(/not permitted to read/)
    end

    it 'does not create a project' do
      expect { result }.not_to change(Project, :count)
    end
  end

  context 'when authenticated and project exists' do
    let(:returned_gid) { result.dig('data', 'remixProject', 'project', 'id') }
    let(:remixed_project) { GlobalID.find(returned_gid) }

    it 'creates a project' do
      expect { result }.to change(Project, :count).by(1)
    end

    it 'returns graphql id for remixed project' do
      expect(returned_gid).to eq Project.order(created_at: :asc).last.to_gid_param
    end

    it 'sets the remix origin' do
      expect(remixed_project.remix_origin).to eq('editor.com')
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
