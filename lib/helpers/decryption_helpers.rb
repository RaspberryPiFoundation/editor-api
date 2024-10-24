# frozen_string_literal: true

require 'attr_encrypted'
require 'base64'

module DecryptionHelpers
  def decrypt_password(encrypted_password)
    hex_key = ENV.fetch('EDITOR_ENCRYPTION_KEY')
    key = [hex_key].pack('H*') # Convert the hex key to binary

    begin
      decipher = OpenSSL::Cipher.new('aes-256-cbc')
      decipher.decrypt
      decipher.key = key
      encrypted_data = Base64.decode64(encrypted_password)
      iv = encrypted_data[0..15]
      encrypted_password = encrypted_data[16..-1]
      decipher.iv = iv
      decipher.update(encrypted_password) + decipher.final
    rescue StandardError => e
      raise "Decryption failed: #{e.message}"
    end
  end
end
