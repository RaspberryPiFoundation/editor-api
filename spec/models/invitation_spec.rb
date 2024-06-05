# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Invitation do
  it 'has a valid factory' do
    invitation = build(:invitation)

    expect(invitation).to be_valid
  end
end
