# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolProject do
  it { is_expected.to belong_to(:school) }
  it { is_expected.to belong_to(:project) }
end
