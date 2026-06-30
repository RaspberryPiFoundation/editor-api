# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Identifiable do
  subject(:extract_token) { identifiable.extract_token(header) }

  let(:identifiable) { Class.new(ActionController::API) { include Identifiable }.new }

  context 'when the header is a raw token' do
    let(:header) { 'secret-token' }

    it { is_expected.to eq('secret-token') }
  end

  context 'when the header is Bearer-prefixed' do
    let(:header) { 'Bearer secret-token' }

    it { is_expected.to eq('secret-token') }
  end

  context 'when the header uses a lowercase bearer prefix' do
    let(:header) { 'bearer secret-token' }

    it { is_expected.to eq('secret-token') }
  end

  context 'when the header is Bearer with no token' do
    let(:header) { 'Bearer ' }

    it { is_expected.to eq('') }
  end
end
