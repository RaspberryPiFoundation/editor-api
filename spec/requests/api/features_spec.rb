# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Features", type: :request do
  let(:headers) { { Authorization: UserProfileMock::TOKEN } }
  let!(:school_class) { create(:school_class, teacher_ids: [teacher.id], school:) }
  let(:school) { create(:school) }
  let(:student) { create(:student, school:) }
  let(:teacher) { create(:teacher, school:) }

  describe "Feature flag API" do
    it "returns a globally-disabled feature as disabled" do
      # Arrange
      Flipper.disable :some_global_feature

      # Act
      get "/api/features"

      # Assert
      expect(response.body).not_to include('"some_global_feature":true')
    end

    it "returns a globally-enabled feature as enabled" do
      # Arrange
      Flipper.enable :some_global_feature

      # Act
      get "/api/features"

      # Assert
      expect(response.body).to include('"some_global_feature":true')
    end

    it "returns a school-level feature as disabled for logged-out user" do
      # Arrange
      Flipper.enable_actor :some_school_level_feature, school

      # Act
      get "/api/features"

      # Assert
      expect(response.body).not_to include('"some_school_level_feature":true')
    end

    it "returns a school-level feature as enabled for a student in that school" do
      # Arrange
      authenticated_in_hydra_as(student)

      Flipper.enable_actor :some_school_level_feature, school

      # Act
      get "/api/features", headers: headers

      # Assert
      expect(response.body).to include('"some_school_level_feature":true')
    end

    it "returns both school-level and global features as enabled for a student in a school" do
      # Arrange
      authenticated_in_hydra_as(student)

      Flipper.enable_actor :some_school_level_feature, school
      Flipper.enable :some_global_feature

      # Act
      get "/api/features", headers: headers

      # Assert
      expect(response.body).to include('"some_school_level_feature":true')
      expect(response.body).to include('"some_global_feature":true')
    end

    # todo: Don't leak the existence of disabled feature flags

  end

  describe "Feature flag web interface" do
    it "is visible at /admin/flipper/features" do
      # Act
      get "/admin/flipper/features"

      # Assert
      expect(response).to have_http_status(:success)
    end

    # todo: Only admins should be able to access UI

  end
end
