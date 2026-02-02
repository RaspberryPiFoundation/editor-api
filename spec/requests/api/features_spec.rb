# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Features' do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }
  let(:admin_user) { create(:admin_user) }

  describe 'Feature flag API' do
    it 'returns a globally-disabled feature as disabled' do
      # Arrange
      Flipper.disable :some_global_feature

      # Act
      get '/api/features'

      # Assert
      expect(response.body).not_to include('some_global_feature')
    end

    it 'returns a globally-enabled feature as enabled' do
      # Arrange
      Flipper.enable :some_global_feature

      # Act
      get '/api/features'

      # Assert
      expect(response.body).to include('some_global_feature')
    end

    it 'returns a school-level feature as disabled for logged-out user' do
      # Arrange
      Flipper.enable_actor :some_school_level_feature, school

      # Act
      get '/api/features'

      # Assert
      expect(response.body).not_to include('some_school_level_feature')
    end

    it 'returns a school-level feature as enabled for a student in that school' do
      # Arrange
      authenticated_in_hydra_as(student)

      Flipper.enable_actor :some_school_level_feature, school

      # Act
      get '/api/features', headers: headers

      # Assert
      expect(response.body).to include('some_school_level_feature')
    end

    it 'returns both school-level and global features as enabled for a student in a school' do
      # Arrange
      authenticated_in_hydra_as(student)

      Flipper.enable_actor :some_school_level_feature, school
      Flipper.enable :some_global_feature

      # Act
      get '/api/features', headers: headers

      # Assert
      expect(response.body).to include('some_school_level_feature')
      expect(response.body).to include('some_global_feature')
    end
  end

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
