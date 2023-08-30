# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProjectError do
  it { is_expected.to respond_to(:user_id) }
  it { is_expected.to respond_to(:error_type) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:error) }
  end
end
