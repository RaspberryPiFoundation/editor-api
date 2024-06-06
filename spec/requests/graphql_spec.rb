# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /graphql' do
  subject(:request) { post(graphql_path, as: :json, params:, headers:) }

  let(:headers) { { Origin: 'editor.com' } }
  let(:params) { nil }

  before do
    allow(EditorApiSchema).to receive(:execute).and_return({})
  end

  shared_examples 'no variables are set' do
    it 'sets an empty hash for the variables' do
      request
      expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(variables: {}))
    end
  end

  shared_examples 'correctly sets the variables' do
    it 'passes them correctly' do
      request
      expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(variables:))
    end
  end

  shared_examples 'an unidentified request' do
    it 'sets the current_user as nil in the context' do
      request
      expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(context: hash_including(current_user: nil)))
    end
  end

  it 'returns OK' do
    request
    expect(response).to be_ok
  end

  it_behaves_like 'an unidentified request'

  it_behaves_like 'no variables are set'

  it 'returns a JSON response' do
    request
    expect(response.content_type).to start_with 'application/json;'
  end

  context 'when an operationName is given' do
    let(:params) { { operationName: operation_name } }
    let(:operation_name) { 'testOperation' }

    it 'sets the operationName correctly' do
      request
      expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(operation_name:))
    end
  end

  context 'when an Authorization header is supplied' do
    let(:headers) { { Authorization: token, Origin: 'editor.com' } }
    let(:token) { '' }

    it_behaves_like 'an unidentified request'

    context 'with a token' do
      let(:token) { UserProfileMock::TOKEN }

      context 'when the token is invalid' do
        before do
          unauthenticated_in_hydra
        end

        it_behaves_like 'an unidentified request'
      end

      context 'when the token is valid' do
        let(:school) { create(:school) }
        let(:owner) { create(:owner, school:) }

        before do
          authenticated_in_hydra_as(owner)
        end

        it 'sets the current_user in the context' do
          request
          expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(context: hash_including(current_user: stubbed_user)))
        end

        it 'sets the request origin from the headers' do
          request
          expect(EditorApiSchema).to have_received(:execute).with(anything, hash_including(context: hash_including(remix_origin: 'editor.com')))
        end
      end
    end
  end

  context 'when variables are given' do
    let(:params) { { variables: } }
    let(:variables) { { 'key' => 'value' } }

    it_behaves_like 'correctly sets the variables'

    context 'when they are a JSON string' do
      subject(:request) { post(graphql_path, as: :url_encoded_form, params:) }

      let(:params) { { variables: variables.to_json } }

      it_behaves_like 'correctly sets the variables'
    end

    context 'when the params are encoded as url_encoded_form' do
      subject(:request) { post(graphql_path, as: :url_encoded_form, params:) }

      it_behaves_like 'correctly sets the variables'
    end

    context 'when variables are set to null' do
      let(:variables) { 'null' }

      it_behaves_like 'no variables are set'
    end

    context 'when variables are an empty string' do
      let(:variables) { '' }

      it_behaves_like 'no variables are set'
    end
  end

  context 'when a query is given' do
    let(:query) { '{ query { hello { id } }' }
    let(:params) { { query: } }

    before do
      allow(EditorApiSchema).to receive(:execute).and_return({})
    end

    it 'passes them correctly' do
      request
      expect(EditorApiSchema).to have_received(:execute).with(query, anything)
    end
  end
end
