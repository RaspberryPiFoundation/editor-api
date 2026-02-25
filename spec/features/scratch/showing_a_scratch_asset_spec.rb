# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Showing a Scratch asset', type: :request do
  it 'returns scratch asset SVG' do
    get '/api/scratch/assets/internalapi/asset/example.svg/get/'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('<svg')
  end
end
