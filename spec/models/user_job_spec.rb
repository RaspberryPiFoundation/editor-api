# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserJob do
  it { is_expected.to validate_presence_of(:good_job_batch_id) }
  it { is_expected.to validate_presence_of(:user_id) }
end
