# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Remix requests', type: :request do
  let!(:original_project) { create(:project) }
  let(:user_id) { 'e0675b6c-dc48-4cd6-8c04-0f7ac05af51a' }

  describe 'create' do
    before do
      mock_phrase_generation
    end

    it 'returns expected response' do
      post "/api/projects/phrases/#{original_project.identifier}/remix",
           params: { remix: { user_id: user_id } }

      expect(response.status).to eq(200)
    end
  end
end
