# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create project error requests' do
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }
  let(:project) { create(:project, user_id:) }
  let(:error) { 'some random test error message' }
  let(:status) { :created }
  let(:error_type) { nil }

  let(:params) do
    {
      error:,
      error_type:,
      user_id:,
      project_id: project.identifier
    }
  end

  let(:expected_body) do
    {
      error:,
      error_type:,
      user_id:,
      project_id: project.id
    }
  end

  before do
    post('/api/project_errors', params:)
  end

  shared_examples 'upload error' do
    it 'creates an error' do
      json_response = JSON.parse(response.body, symbolize_names: true)[:data]
      expect(json_response).to include(expected_body)
    end

    it 'returns the correct status code' do
      expect(response).to have_http_status(status)
    end
  end

  shared_examples 'invalid request' do
    it 'returns an empty body data object' do
      json_response = JSON.parse(response.body, symbolize_names: true)[:data]
      expect(json_response).to eq([])
    end

    it 'returns bad request status code' do
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe 'with a user and project' do
    context 'with a valid error param' do
      it_behaves_like 'upload error'
    end

    context 'without an error param' do
      let(:params) do
        {
          user_id:,
          project_id: project.identifier
        }
      end

      it_behaves_like 'invalid request'
    end
  end

  describe 'without a user and project' do
    let(:error_type) { nil }
    let(:params) do
      {
        error:,
        error_type:
      }
    end

    let(:expected_body) do
      {
        error:,
        error_type:
      }
    end

    context 'with a valid error param' do
      it_behaves_like 'upload error'
    end

    context 'with a valid error and error_type' do
      let(:error_type) { "TestError" }
      it_behaves_like 'upload error'
    end

    context 'without an error param' do
      let(:params) { {} }

      it_behaves_like 'invalid request'
    end
  end

  describe 'with an unknown project' do
    let(:params) do
      {
        error:,
        error_type:,
        project: 'some-made-up-slug'
      }
    end

    let(:expected_body) do
      {
        error:,
        error_type:
      }
    end

    context 'with a valid error param' do
      it_behaves_like 'upload error'
    end

    context 'with a valid error and error_type' do
      let(:error_type) { "TestError" }
      it_behaves_like 'upload error'
    end
  end
end
