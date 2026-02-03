# frozen_string_literal: true

RSpec.shared_examples 'an authenticated API request' do |http_method, url:|
  let(:expected_url) { instance_exec(&url) }

  it 'makes a request to the profile api host' do
    subject
    expect(WebMock).to have_requested(http_method, expected_url)
  end

  it 'includes token in the authorization request header' do
    subject
    expect(WebMock).to have_requested(http_method, expected_url)
      .with(headers: { 'Authorization' => "Bearer #{token}" })
  end

  it 'includes the profile api key in the x-api-key request header' do
    subject
    expect(WebMock).to have_requested(http_method, expected_url)
      .with(headers: { 'X-API-KEY' => api_key })
  end

  it 'sets accept header to json' do
    subject
    expect(WebMock).to have_requested(http_method, expected_url)
      .with(headers: { 'Accept' => 'application/json' })
  end
end

RSpec.shared_examples 'an authenticated JSON API request' do |http_method, url:|
  let(:expected_url) { instance_exec(&url) }

  it_behaves_like 'an authenticated API request', http_method, url: url

  it 'sets content-type of request to json' do
    subject
    expect(WebMock).to have_requested(http_method, expected_url)
      .with(headers: { 'Content-Type' => 'application/json' })
  end
end

RSpec.shared_examples 'a request that handles standard HTTP errors' do |http_method, url:|
  let(:expected_url) { instance_exec(&url) }

  it 'raises faraday exception for 4xx and 5xx responses' do
    stub_request(http_method, expected_url).to_return(status: 403)
    expect { subject }.to raise_error(Faraday::Error)
  end

  it 'raises faraday exception for 4xx and 5xx responses' do
    stub_request(http_method, expected_url).to_return(status: 500)
    expect { subject }.to raise_error(Faraday::Error)
  end

  it 'does not raise faraday exception for 401' do
    stub_request(http_method, expected_url).to_return(status: 401)
    expect { subject }.not_to raise_error(Faraday::Error)
  end

  it 'raises UnauthorizedError on 401' do
    stub_request(http_method, expected_url).to_return(status: 401)
    expect { subject }.to raise_error(ProfileApiClient::UnauthorizedError)
  end
end

RSpec.shared_examples 'a request that handles an unexpected response status' do |http_method, url:, status:|
  let(:expected_url) { instance_exec(&url) }

  it 'raises exception if anything other than expected status code is returned' do
    stub_request(http_method, expected_url).to_return(status: status)
    expect { subject }.to raise_error(ProfileApiClient::UnexpectedResponse)
  end
end
