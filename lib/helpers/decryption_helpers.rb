# frozen_string_literal: true

require 'openssl'
require 'base64'

class DecryptionHelpers
  def self.decrypt_password(encrypted_password)
    hex_key = ENV.fetch('EDITOR_ENCRYPTION_KEY')
    key = [hex_key].pack('H*') # Convert the hex key to binary

    begin
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = key

      encrypted_data = Base64.decode64(encrypted_password)
      iv = encrypted_data[0, 16]
      encrypted_password = encrypted_data[16..]

      cipher.iv = iv
      cipher.update(encrypted_password) + cipher.final
    rescue StandardError => e
      raise "Decryption failed: #{e.message}"
    end
  end
end
