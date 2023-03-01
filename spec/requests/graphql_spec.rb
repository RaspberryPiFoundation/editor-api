# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /graphql' do
  subject { response }

  let(:params) { {} }
  let(:headers) { {} }
  let(:json_response) { response.parsed_body }

  before { post graphql_path, params:, headers: }

  it { is_expected.to be_ok }

  it 'returns errors' do
    expect(json_response['errors']).to be_a Array
  end

  context 'with a query' do
    let(:params) { { query: } }
    let(:query) { '' }

    it { is_expected.to be_ok }

    it 'returns errors' do
      expect(json_response['errors']).to be_a Array
    end

    context 'with a valid query' do
      let(:query) { '{ node("xyz") }' }

      it { is_expected.to be_ok }

      it 'returns data' do
        expect(json_response.dig('data', 'node')).to be_nil
      end
    end
  end
end
