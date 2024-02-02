# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApiError::Base do
  subject { described_class }

  before do
    stub_const('EditorApiError::Base::CODE', 'TESTING')
  end

  it 'can be initialized with extensions' do
    expect(described_class.new('message', extensions: { foo: :bar }).extensions).to include(foo: :bar)
  end

  it 'sets the error code' do
    expect(described_class.new('message').extensions).to include(code: 'TESTING')
  end
end
