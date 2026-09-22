# frozen_string_literal: true

RSpec.shared_examples 'a hidden ownership transfer' do
  it 'responds 404 Not Found, without revealing that a transfer exists' do
    get("/api/schools/#{school.id}/ownership_transfer", headers:)
    expect(response).to have_http_status(:not_found)
  end
end
