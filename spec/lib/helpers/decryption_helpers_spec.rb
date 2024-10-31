# frozen_string_literal: true

require 'rails_helper'
require 'openssl'
require 'base64'

RSpec.describe DecryptionHelpers do
  let(:key) { 'a1b2c3d4e5f67890123456789abcdef0123456789abcdef0123456789abcdef0' } # 256-bit key in hex
  let(:password) { 'Student2024' }
  let(:encrypted_password) { 'SaoXlDBAyiAFoMH3VsddhdA7JWnM8P8by1wOjBUWH2g=' } # An encrypted password

  before do
    allow(ENV).to receive(:fetch).with('EDITOR_ENCRYPTION_KEY').and_return(key)
  end

  it 'decrypts the password successfully' do
    expect(described_class.decrypt_password(encrypted_password)).to eq(password)
  end

  it 'raises an error with an incorrect key' do
    allow(ENV).to receive(:fetch).with('EDITOR_ENCRYPTION_KEY').and_return('b' * 64)
    expect { described_class.decrypt_password(encrypted_password) }.to raise_error(RuntimeError, /Decryption failed/)
  end

  it 'raises an error with invalid encrypted data' do
    invalid_encrypted_password = Base64.encode64('invalid_data')
    expect { described_class.decrypt_password(invalid_encrypted_password) }.to raise_error(RuntimeError, /Decryption failed/)
  end
end
