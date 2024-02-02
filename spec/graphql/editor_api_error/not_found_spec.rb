# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorApiError::NotFound do
  subject { described_class }

  it 'sets the error code' do
    expect(described_class.new('message').extensions).to include(code: 'NOT_FOUND')
  end
end
