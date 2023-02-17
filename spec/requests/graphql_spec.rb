# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'POST /graphql' do
  subject { response }

  let(:params) { {} }
  let(:json_response) { JSON.parse(response.body) }

  before { post graphql_path, params: }

  context 'with a query' do
    let(:params) { { query: query_string } }
    let(:query_string) { '' }

    it 'returns test data' do
      expect(json_response['errors']).to be_a Array
    end

    context 'with the venues when no data' do
      let(:query_string) { '{ projects }' }

      it 'returns test data' do
        expect(json_response.dig('data', 'projects')).to be_nil
      end
    end

    context 'with the venue when no data' do
      let(:query_string) { '{ project }' }

      it 'returns error if' do
        expect(json_response['errors']).to be_a Array
      end
    end
  end
end
