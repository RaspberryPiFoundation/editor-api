# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Features", type: :request do

  describe "Feature flag API" do
    it "returns a globally-enabled feature as enabled" do
      # Arrange
      Flipper.enable :some_cool_feature

      # Act
      get "/api/features"

      # Assert
      expect(response.body).to include('"some_cool_feature":true')
    end
  end

  describe "Feature flag web interface" do
    it "is visible at /admin/flipper/features" do
      # Act
      get "/admin/flipper/features"

      # Assert
      expect(response).to have_http_status(:success)
    end
  end
end
