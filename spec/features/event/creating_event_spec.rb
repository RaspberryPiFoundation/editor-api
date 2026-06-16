# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Create events', type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let(:user) { create(:user) }

  before do
    authenticated_in_hydra_as(user)
  end

  it('posting event returns created status') do
    post('/api/events', headers:, params: { event: { name: 'Test Event', properties: { key: 'value' } } })
    expect(response).to have_http_status(:created)
  end

  it('creating an event without a name returns unprocessable content') do
    post('/api/events', headers:, params: { event: { properties: { key: 'value' } } })
    expect(response).to have_http_status(:unprocessable_content)
  end

  it('created event is stored in the database with correct attributes') do
    post('/api/events', headers:, params: { event: { name: 'Test Event', properties: { key: 'value' } } })
    event = Event.last
    expect(event.name).to eq('Test Event')
    expect(event.properties).to eq({ 'key' => 'value' })
  end

  it('creating an event without authentication returns unauthorized') do
    post('/api/events', params: { event: { name: 'Test Event', properties: { key: 'value' } } })
    expect(response).to have_http_status(:unauthorized)
  end
end
