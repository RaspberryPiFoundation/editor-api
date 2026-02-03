# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Flipper' do
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:admin_user) { create(:admin_user) }

  describe 'Feature flag web interface' do
    it 'is hidden from unauthenticated users' do
      # Act
      get '/admin/flipper/features'

      # Assert
      expect(response).to have_http_status(:not_found)
    end

    it 'is hidden from student users' do
      # Arrange
      sign_in student

      # Act
      get '/admin/flipper/features'

      # Assert
      expect(response).to have_http_status(:not_found)
    end

    it 'is hidden from teacher users' do
      # Arrange
      sign_in teacher

      # Act
      get '/admin/flipper/features'

      # Assert
      expect(response).to have_http_status(:not_found)
    end

    it 'is visible to admins' do
      # Arrange
      sign_in admin_user

      # Act
      get '/admin/flipper/features'

      # Assert
      expect(response).to have_http_status(:success)
    end
  end
end
