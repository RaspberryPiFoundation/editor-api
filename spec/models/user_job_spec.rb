# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserJob do
  it { is_expected.to belong_to(:good_job) }
  it { is_expected.to validate_presence_of(:user_id) }
end
