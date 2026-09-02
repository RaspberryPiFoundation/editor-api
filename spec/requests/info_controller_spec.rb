# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InfoController do
  describe 'GET /info/release' do
    subject(:request) { get '/info/release' }

    it 'returns the deployed commit sha as text' do
      ClimateControl.modify(HEROKU_SLUG_COMMIT: 'abc123') do
        request
        expect(response.body).to eq('abc123')
      end
    end

    it 'returns unknown when the sha is unavailable' do
      ClimateControl.modify(HEROKU_SLUG_COMMIT: nil) do
        request
        expect(response.body).to eq('unknown')
      end
    end
  end
end
