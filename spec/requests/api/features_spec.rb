# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Features", type: :request do
  it "Returns a globally-enabled feature as enabled" do
    # Arrange
    Flipper.enable :some_cool_feature

    # Act
    get "/api/features"

    # Assert
    expect(response.body).to include('"some_cool_feature":true')
  end
end
