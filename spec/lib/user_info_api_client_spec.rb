# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserInfoApiClient do
  describe '.fetch_by_ids' do
    subject(:result) { described_class.fetch_by_ids(user_ids) }

    let(:user_ids) { [SecureRandom.uuid] }

    it 'returns an empty Array when the ids are blank' do
      expect(described_class.fetch_by_ids([])).to eq []
    end

    context 'when the API responds with a blank body' do
      before do
        stub_request(:get, "#{described_class::API_URL}/users")
          .with(headers: { Authorization: "Bearer #{described_class::API_KEY}" })
          .to_return(status: 200, body: '')
      end

      it 'returns an empty Array rather than nil' do
        expect(result).to eq []
      end
    end
  end
end
