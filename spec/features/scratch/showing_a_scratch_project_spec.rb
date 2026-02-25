# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a Scratch project', type: :request do
  it 'returns scratch project JSON' do
    get '/api/scratch/projects/any-identifier'

    expect(response).to have_http_status(:ok)

    data = JSON.parse(response.body, symbolize_names: true)
    expect(data).to have_key(:targets)
  end
end
